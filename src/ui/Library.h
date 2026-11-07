// SPDX-License-Identifier: MIT
#pragma once

#include "models/ChannelListModel.h"
#include "models/SourceListModel.h"

#include <QObject>
#include <QQmlEngine>

#include <memory>

class QNetworkAccessManager;

namespace iptvx {
class Database;
class PlaylistLoader;
class SourceRepository;
} // namespace iptvx

namespace iptvx::ui {

/// Facade between QML and the core layer (QML singleton `Library`).
///
/// Owns the database, the source list and the channel model of the active
/// source. Only one source's channels are kept in memory at a time:
/// switching sources releases the previous ChannelStore.
class Library : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(iptvx::ui::SourceListModel *sources READ sources CONSTANT)
    Q_PROPERTY(iptvx::ui::ChannelListModel *channels READ channels CONSTANT)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(qreal progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(QString errorString READ errorString NOTIFY errorStringChanged)
    Q_PROPERTY(QString activeSourceId READ activeSourceId NOTIFY activeSourceChanged)
    Q_PROPERTY(QString activeSourceName READ activeSourceName NOTIFY activeSourceChanged)
    Q_PROPERTY(QStringList epgUrls READ epgUrls NOTIFY activeSourceChanged)

public:
    explicit Library(QObject *parent = nullptr);
    ~Library() override;

    SourceListModel *sources() const { return m_sources; }
    ChannelListModel *channels() const { return m_channels; }
    bool busy() const { return m_busy; }
    qreal progress() const { return m_progress; }
    QString errorString() const { return m_error; }
    QString activeSourceId() const { return m_activeId; }
    QString activeSourceName() const;
    QStringList epgUrls() const { return m_epgUrls; }

    Q_INVOKABLE bool addM3uUrl(const QString &name, const QString &url, const QString &userAgent = {});
    Q_INVOKABLE bool addM3uFile(const QString &name, const QUrl &file);
    Q_INVOKABLE bool addXtream(const QString &name, const QString &server, const QString &username,
                               const QString &password);
    Q_INVOKABLE bool removeSource(const QString &id);
    Q_INVOKABLE void selectSource(const QString &id);
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void clearError();

    /// Approximate bytes held by the active channel catalog.
    Q_INVOKABLE qint64 catalogMemory() const;

signals:
    void busyChanged();
    void progressChanged();
    void errorStringChanged();
    void activeSourceChanged();
    /// Emitted after a source was added and selected (for UI feedback).
    void sourceAdded(const QString &id);

private:
    bool addSource(Source source);
    void setBusy(bool busy);
    void setError(const QString &error);
    void setProgress(qreal progress);

    std::unique_ptr<Database> m_db;
    std::unique_ptr<SourceRepository> m_repo;
    QNetworkAccessManager *m_network = nullptr;
    PlaylistLoader *m_loader = nullptr;
    SourceListModel *m_sources = nullptr;
    ChannelListModel *m_channels = nullptr;

    QString m_activeId;
    QStringList m_epgUrls;
    QString m_error;
    qreal m_progress = -1;
    bool m_busy = false;
};

} // namespace iptvx::ui
