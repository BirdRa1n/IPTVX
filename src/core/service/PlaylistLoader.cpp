// SPDX-License-Identifier: MIT
#include "service/PlaylistLoader.h"

#include "parser/M3uParser.h"
#include "provider/XtreamClient.h"

#include <QDir>
#include <QFile>
#include <QFutureWatcher>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QSaveFile>
#include <QStandardPaths>
#include <QtConcurrentRun>

using namespace Qt::StringLiterals;

namespace iptvx {

PlaylistLoader::PlaylistLoader(QNetworkAccessManager *network, QString cacheDir, QObject *parent)
    : QObject(parent)
    , m_network(network)
    , m_cacheDir(std::move(cacheDir))
{
    QDir().mkpath(m_cacheDir);
}

PlaylistLoader::~PlaylistLoader()
{
    cancel();
}

QString PlaylistLoader::defaultCacheDir()
{
    return QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + u"/playlists"_s;
}

QString PlaylistLoader::cachePath(const QString &sourceId) const
{
    return m_cacheDir + u'/' + sourceId + u".m3u"_s;
}

void PlaylistLoader::cancel()
{
    ++m_generation; // invalidates callbacks of the running load
    if (m_cancel)
        m_cancel->store(true);
    if (m_reply)
        m_reply->abort();
    if (m_xtream) {
        m_xtream->abort();
        m_xtream->deleteLater();
    }
    m_file.reset(); // discards a partial download (QSaveFile never commits)
    m_busy = false;
}

void PlaylistLoader::load(const Source &source, bool forceRefresh)
{
    cancel();
    m_busy = true;

    switch (source.type) {
    case SourceType::M3uFile:
        parseFile(source.id, source.url);
        return;
    case SourceType::M3uUrl:
        if (!forceRefresh && QFile::exists(cachePath(source.id)))
            parseFile(source.id, cachePath(source.id));
        else
            download(source);
        return;
    case SourceType::Xtream:
        loadXtream(source);
        return;
    case SourceType::Stalker:
        fail(source.id, tr("Stalker portals are not supported yet."));
        return;
    }
}

void PlaylistLoader::fail(const QString &sourceId, const QString &error)
{
    m_busy = false;
    emit failed(sourceId, error);
}

void PlaylistLoader::parseFile(const QString &sourceId, const QString &path)
{
    const quint64 generation = m_generation;
    m_cancel = std::make_shared<std::atomic_bool>(false);

    auto *watcher = new QFutureWatcher<M3uParseResult>(this);
    connect(watcher, &QFutureWatcherBase::finished, this, [this, watcher, sourceId, generation] {
        watcher->deleteLater();
        if (generation != m_generation)
            return; // superseded or cancelled
        M3uParseResult result = watcher->result();
        if (!result.channels) {
            fail(sourceId, tr("Could not open the playlist file."));
            return;
        }
        m_busy = false;
        emit loaded(sourceId, std::move(result.channels), result.epgUrls);
    });
    watcher->setFuture(QtConcurrent::run([path, cancel = m_cancel]() -> M3uParseResult {
        QFile file(path);
        if (!file.open(QIODevice::ReadOnly))
            return {};
        return M3uParser::parse(file, cancel.get());
    }));
}

void PlaylistLoader::download(const Source &source)
{
    if (!m_network) {
        fail(source.id, tr("Network unavailable."));
        return;
    }
    m_file = std::make_unique<QSaveFile>(cachePath(source.id));
    if (!m_file->open(QIODevice::WriteOnly)) {
        const QString error = m_file->errorString();
        m_file.reset();
        fail(source.id, error);
        return;
    }

    QNetworkRequest request { QUrl(source.url) };
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    request.setTransferTimeout(60'000);
    if (!source.userAgent.isEmpty())
        request.setHeader(QNetworkRequest::UserAgentHeader, source.userAgent);

    m_reply = m_network->get(request);
    // Small read buffer: data is flushed to disk as it arrives.
    m_reply->setReadBufferSize(256 * 1024);

    const QString sourceId = source.id;
    connect(m_reply, &QNetworkReply::readyRead, this, [this] {
        if (m_file && m_reply)
            m_file->write(m_reply->readAll());
    });
    connect(m_reply, &QNetworkReply::downloadProgress, this, &PlaylistLoader::progress);
    connect(m_reply, &QNetworkReply::finished, this, [this, sourceId, reply = m_reply] {
        reply->deleteLater();
        if (reply->error() == QNetworkReply::OperationCanceledError || !m_file)
            return;
        if (reply->error() != QNetworkReply::NoError) {
            m_file.reset();
            fail(sourceId, reply->errorString());
            return;
        }
        m_file->write(reply->readAll());
        const bool committed = m_file->commit();
        const QString error = m_file->errorString();
        m_file.reset();
        if (!committed) {
            fail(sourceId, error);
            return;
        }
        parseFile(sourceId, cachePath(sourceId));
    });
}

void PlaylistLoader::loadXtream(const Source &source)
{
    const quint64 generation = m_generation;
    m_xtream = new XtreamClient(m_network, { QUrl(source.url), source.username, source.password }, this);
    m_xtream->fetchLiveChannels(
        [this, generation, sourceId = source.id](std::shared_ptr<ChannelStore> store, QString error) {
            if (generation != m_generation)
                return;
            if (m_xtream) {
                m_xtream->deleteLater();
                m_xtream = nullptr;
            }
            if (!error.isEmpty() || !store) {
                fail(sourceId, error.isEmpty() ? tr("Empty response from server.") : error);
                return;
            }
            m_busy = false;
            emit loaded(sourceId, std::move(store), {});
        });
}

} // namespace iptvx
