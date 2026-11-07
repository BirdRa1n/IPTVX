// SPDX-License-Identifier: MIT
#pragma once

#include "model/ChannelStore.h"
#include "model/Source.h"

#include <QObject>
#include <QPointer>

#include <atomic>
#include <memory>

class QNetworkAccessManager;
class QNetworkReply;
class QSaveFile;

namespace iptvx {

class XtreamClient;

/// Turns a Source definition into a ChannelStore.
///
/// * M3U file: parsed directly from disk on a worker thread.
/// * M3U URL: streamed to a cache file (never fully buffered in RAM), then
///   parsed from disk. The cached copy is reused on the next start unless a
///   refresh is requested, so the app works offline and starts instantly.
/// * Xtream: catalog fetched through XtreamClient.
///
/// One load runs at a time; starting a new load cancels the previous one.
class PlaylistLoader : public QObject
{
    Q_OBJECT

public:
    PlaylistLoader(QNetworkAccessManager *network, QString cacheDir, QObject *parent = nullptr);
    ~PlaylistLoader() override;

    void load(const Source &source, bool forceRefresh = false);
    void cancel();
    bool isBusy() const { return m_busy; }

    /// Cache file used for an M3U URL source.
    QString cachePath(const QString &sourceId) const;

    /// Default cache directory (QStandardPaths::CacheLocation/playlists).
    static QString defaultCacheDir();

signals:
    void progress(qint64 bytesReceived, qint64 bytesTotal);
    void loaded(const QString &sourceId, iptvx::ChannelStorePtr channels, const QStringList &epgUrls);
    void failed(const QString &sourceId, const QString &error);

private:
    void parseFile(const QString &sourceId, const QString &path);
    void download(const Source &source);
    void loadXtream(const Source &source);
    void fail(const QString &sourceId, const QString &error);

    QPointer<QNetworkAccessManager> m_network;
    QString m_cacheDir;
    QPointer<QNetworkReply> m_reply;
    std::unique_ptr<QSaveFile> m_file;
    QPointer<XtreamClient> m_xtream;
    std::shared_ptr<std::atomic_bool> m_cancel;
    quint64 m_generation = 0;
    bool m_busy = false;
};

} // namespace iptvx
