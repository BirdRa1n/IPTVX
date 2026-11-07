// SPDX-License-Identifier: MIT
#include "Library.h"

#include "service/PlaylistLoader.h"
#include "storage/Database.h"
#include "storage/SourceRepository.h"

#include <QFile>
#include <QFileInfo>
#include <QNetworkAccessManager>
#include <QSettings>
#include <QUrl>

using namespace Qt::StringLiterals;

namespace iptvx::ui {

namespace {
const QString kLastSourceKey = u"library/lastSourceId"_s;
} // namespace

Library::Library(QObject *parent)
    : QObject(parent)
    , m_db(std::make_unique<Database>())
    , m_network(new QNetworkAccessManager(this))
    , m_sources(new SourceListModel(this))
    , m_channels(new ChannelListModel(this))
{
    if (!m_db->open(Database::defaultPath()))
        setError(tr("Could not open the library database: %1").arg(m_db->lastError()));
    m_repo = std::make_unique<SourceRepository>(m_db->connection());
    m_sources->setSources(m_repo->all());

    m_loader = new PlaylistLoader(m_network, PlaylistLoader::defaultCacheDir(), this);
    connect(m_loader, &PlaylistLoader::progress, this, [this](qint64 received, qint64 total) {
        setProgress(total > 0 ? qreal(received) / qreal(total) : -1);
    });
    connect(m_loader, &PlaylistLoader::loaded, this,
            [this](const QString &id, ChannelStorePtr store, const QStringList &epgUrls) {
                if (id != m_activeId)
                    return;
                m_epgUrls = epgUrls;
                m_channels->setStore(std::move(store));
                setProgress(-1);
                setBusy(false);
                emit activeSourceChanged();
            });
    connect(m_loader, &PlaylistLoader::failed, this, [this](const QString &id, const QString &error) {
        if (id != m_activeId)
            return;
        setProgress(-1);
        setBusy(false);
        setError(error);
    });

    const QString last = QSettings().value(kLastSourceKey).toString();
    if (m_sources->findById(last))
        selectSource(last);
    else if (m_sources->count() > 0)
        selectSource(m_sources->sources().first().id);
}

Library::~Library() = default;

QString Library::activeSourceName() const
{
    const Source *s = m_sources->findById(m_activeId);
    return s ? s->name : QString();
}

bool Library::addSource(Source source)
{
    clearError();
    const auto stored = m_repo->insert(std::move(source));
    if (!stored) {
        setError(tr("Could not save the source."));
        return false;
    }
    m_sources->append(*stored);
    selectSource(stored->id);
    emit sourceAdded(stored->id);
    return true;
}

bool Library::addM3uUrl(const QString &name, const QString &url, const QString &userAgent)
{
    const QUrl parsed = QUrl::fromUserInput(url.trimmed());
    if (!parsed.isValid() || parsed.host().isEmpty()) {
        setError(tr("Enter a valid playlist URL."));
        return false;
    }
    Source s;
    s.type = SourceType::M3uUrl;
    s.url = parsed.toString();
    s.name = name.trimmed().isEmpty() ? parsed.host() : name.trimmed();
    s.userAgent = userAgent.trimmed();
    return addSource(std::move(s));
}

bool Library::addM3uFile(const QString &name, const QUrl &file)
{
    const QString path = file.isLocalFile() ? file.toLocalFile() : file.toString();
    if (!QFileInfo::exists(path)) {
        setError(tr("The selected file does not exist."));
        return false;
    }
    Source s;
    s.type = SourceType::M3uFile;
    s.url = path;
    s.name = name.trimmed().isEmpty() ? QFileInfo(path).completeBaseName() : name.trimmed();
    return addSource(std::move(s));
}

bool Library::addXtream(const QString &name, const QString &server, const QString &username,
                        const QString &password)
{
    const QUrl parsed = QUrl::fromUserInput(server.trimmed());
    if (!parsed.isValid() || parsed.host().isEmpty() || username.isEmpty()) {
        setError(tr("Enter the server URL, username and password."));
        return false;
    }
    Source s;
    s.type = SourceType::Xtream;
    s.url = parsed.toString();
    s.username = username.trimmed();
    s.password = password;
    s.name = name.trimmed().isEmpty() ? parsed.host() : name.trimmed();
    return addSource(std::move(s));
}

bool Library::removeSource(const QString &id)
{
    if (!m_repo->remove(id))
        return false;
    QFile::remove(m_loader->cachePath(id));
    m_sources->removeById(id);
    if (id == m_activeId) {
        m_loader->cancel();
        m_activeId.clear();
        m_epgUrls.clear();
        m_channels->setStore(nullptr); // frees the catalog
        setBusy(false);
        emit activeSourceChanged();
        if (m_sources->count() > 0)
            selectSource(m_sources->sources().first().id);
    }
    return true;
}

void Library::selectSource(const QString &id)
{
    const Source *source = m_sources->findById(id);
    if (!source || (id == m_activeId && (m_busy || m_channels->store())))
        return;
    clearError();
    m_activeId = id;
    QSettings().setValue(kLastSourceKey, id);
    // Release the previous catalog before loading the next one so two
    // catalogs never coexist in memory.
    m_channels->setStore(nullptr);
    m_epgUrls.clear();
    emit activeSourceChanged();
    setBusy(true);
    m_loader->load(*source);
}

void Library::refresh()
{
    const Source *source = m_sources->findById(m_activeId);
    if (!source)
        return;
    clearError();
    setBusy(true);
    m_loader->load(*source, /*forceRefresh=*/true);
}

void Library::clearError()
{
    setError({});
}

qint64 Library::catalogMemory() const
{
    return m_channels->store() ? m_channels->store()->memoryFootprint() : 0;
}

void Library::setBusy(bool busy)
{
    if (busy == m_busy)
        return;
    m_busy = busy;
    emit busyChanged();
}

void Library::setError(const QString &error)
{
    if (error == m_error)
        return;
    m_error = error;
    emit errorStringChanged();
}

void Library::setProgress(qreal progress)
{
    if (qFuzzyCompare(progress + 2, m_progress + 2))
        return;
    m_progress = progress;
    emit progressChanged();
}

} // namespace iptvx::ui
