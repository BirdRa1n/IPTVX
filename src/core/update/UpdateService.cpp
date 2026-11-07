// SPDX-License-Identifier: MIT
#include "update/UpdateService.h"

#include <QCryptographicHash>
#include <QDir>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QSaveFile>

using namespace Qt::StringLiterals;

namespace iptvx::update {

namespace {

QNetworkRequest githubRequest(const QUrl &url, const QString &version, const QByteArray &accept)
{
    QNetworkRequest request(url);
    // GitHub rejects API calls without a User-Agent.
    request.setHeader(QNetworkRequest::UserAgentHeader, u"IPTVX/%1"_s.arg(version));
    request.setRawHeader("Accept", accept);
    request.setRawHeader("X-GitHub-Api-Version", "2022-11-28");
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    return request;
}

} // namespace

UpdateService::UpdateService(QNetworkAccessManager *network, QString repository,
                             QString currentVersion, QObject *parent)
    : QObject(parent)
    , m_network(network)
    , m_repository(std::move(repository))
    , m_currentVersion(std::move(currentVersion))
{
}

UpdateService::~UpdateService()
{
    cancel();
}

void UpdateService::cancel()
{
    if (m_reply)
        m_reply->abort();
    m_file.reset();
    m_hash.reset();
}

void UpdateService::check()
{
    if (!m_network) {
        emit checkFailed(tr("Network unavailable."));
        return;
    }
    const QUrl url(u"https://api.github.com/repos/%1/releases/latest"_s.arg(m_repository));
    QNetworkRequest request = githubRequest(url, m_currentVersion, "application/vnd.github+json");
    request.setTransferTimeout(20'000);
    QNetworkReply *reply = m_network->get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply] {
        reply->deleteLater();
        const int status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        if (status == 404) { // no published release yet
            emit upToDate(m_currentVersion);
            return;
        }
        if (reply->error() != QNetworkReply::NoError) {
            emit checkFailed(reply->errorString());
            return;
        }
        QString error;
        const auto release = parseRelease(reply->readAll(), &error);
        if (!release) {
            emit checkFailed(error);
            return;
        }
        if (compareVersions(release->version, m_currentVersion) <= 0) {
            emit upToDate(release->version);
            return;
        }
        emit updateAvailable(*release, selectAsset(*release, Platform::current()));
    });
}

void UpdateService::download(const ReleaseAsset &asset, const QString &directory)
{
    cancel();
    if (!m_network) {
        emit downloadFailed(tr("Network unavailable."));
        return;
    }
    QDir().mkpath(directory);
    const QString path = QDir(directory).filePath(asset.name);
    m_file = std::make_unique<QSaveFile>(path);
    if (!m_file->open(QIODevice::WriteOnly)) {
        const QString error = m_file->errorString();
        m_file.reset();
        emit downloadFailed(error);
        return;
    }
    m_hash = std::make_unique<QCryptographicHash>(QCryptographicHash::Sha256);

    QNetworkRequest request = githubRequest(asset.url, m_currentVersion, "application/octet-stream");
    request.setTransferTimeout(60'000);
    m_reply = m_network->get(request);
    m_reply->setReadBufferSize(512 * 1024);

    connect(m_reply, &QNetworkReply::readyRead, this, [this] {
        if (!m_file || !m_reply)
            return;
        const QByteArray chunk = m_reply->readAll();
        m_hash->addData(chunk);
        m_file->write(chunk);
    });
    connect(m_reply, &QNetworkReply::downloadProgress, this, &UpdateService::downloadProgress);
    connect(m_reply, &QNetworkReply::finished, this, [this, reply = m_reply, asset, path] {
        reply->deleteLater();
        if (reply->error() == QNetworkReply::OperationCanceledError || !m_file)
            return;
        if (reply->error() != QNetworkReply::NoError) {
            m_file.reset();
            emit downloadFailed(reply->errorString());
            return;
        }
        const QByteArray rest = reply->readAll();
        m_hash->addData(rest);
        m_file->write(rest);

        const qint64 written = m_file->size();
        const QByteArray digest = m_hash->result().toHex();
        QString error;
        if (asset.size > 0 && written != asset.size)
            error = tr("The download is incomplete.");
        else if (!asset.sha256.isEmpty() && digest != asset.sha256)
            error = tr("The download is corrupted (checksum mismatch).");
        if (!error.isEmpty()) {
            m_file.reset(); // discards the temporary file
            emit downloadFailed(error);
            return;
        }
        if (!m_file->commit()) {
            error = m_file->errorString();
            m_file.reset();
            emit downloadFailed(error);
            return;
        }
        m_file.reset();
        m_hash.reset();
        emit downloaded(path);
    });
}

} // namespace iptvx::update
