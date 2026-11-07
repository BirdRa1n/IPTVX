// SPDX-License-Identifier: MIT
#pragma once

#include "update/Release.h"

#include <QObject>
#include <QQmlEngine>

#include <optional>

class QNetworkAccessManager;

namespace iptvx::update {
class UpdateService;
}

namespace iptvx::ui {

/// QML singleton `Updates`: checks GitHub Releases for a newer IPTVX, then
/// downloads and installs the build for this platform on request.
class Updates : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    enum State {
        Idle,
        Checking,
        UpToDate,
        Available,
        Downloading,
        ReadyToInstall,
        Failed,
    };
    Q_ENUM(State)

private:
    Q_PROPERTY(State state READ state NOTIFY stateChanged)
    Q_PROPERTY(QString currentVersion READ currentVersion CONSTANT)
    Q_PROPERTY(QString latestVersion READ latestVersion NOTIFY releaseChanged)
    Q_PROPERTY(QString releaseNotes READ releaseNotes NOTIFY releaseChanged)
    Q_PROPERTY(QUrl releaseUrl READ releaseUrl NOTIFY releaseChanged)
    Q_PROPERTY(bool canInstall READ canInstall NOTIFY releaseChanged)
    Q_PROPERTY(qint64 downloadSize READ downloadSize NOTIFY releaseChanged)
    Q_PROPERTY(QString platformLabel READ platformLabel CONSTANT)
    Q_PROPERTY(qreal progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(QString errorString READ errorString NOTIFY stateChanged)
    Q_PROPERTY(bool autoCheck READ autoCheck WRITE setAutoCheck NOTIFY autoCheckChanged)
    Q_PROPERTY(bool dismissed READ dismissed WRITE setDismissed NOTIFY dismissedChanged)

public:
    explicit Updates(QObject *parent = nullptr);
    ~Updates() override;

    State state() const { return m_state; }
    QString currentVersion() const;
    QString latestVersion() const { return m_release ? m_release->version : QString(); }
    QString releaseNotes() const { return m_release ? m_release->notes : QString(); }
    QUrl releaseUrl() const;
    bool canInstall() const { return m_asset.has_value(); }
    qint64 downloadSize() const { return m_asset ? m_asset->size : 0; }
    QString platformLabel() const;
    qreal progress() const { return m_progress; }
    QString errorString() const { return m_error; }
    bool autoCheck() const;
    void setAutoCheck(bool enabled);
    bool dismissed() const { return m_dismissed; }
    void setDismissed(bool dismissed);

    /// Checks on startup (after a short delay) unless disabled in settings
    /// or IPTVX_NO_UPDATE_CHECK is set (developer sandbox).
    Q_INVOKABLE void checkOnStartup();
    Q_INVOKABLE void check();
    Q_INVOKABLE void download();
    Q_INVOKABLE void cancelDownload();
    /// Launches the installer and quits IPTVX.
    Q_INVOKABLE void installAndRestart();
    Q_INVOKABLE void openReleasePage() const;

    /// Developer tooling only (IPTVX_UPDATE_PREVIEW): shows a synthetic
    /// release so the update UI can be checked without publishing one.
    void previewRelease(const QString &version);

signals:
    void stateChanged();
    void releaseChanged();
    void progressChanged();
    void autoCheckChanged();
    void dismissedChanged();

private:
    void setState(State state, const QString &error = {});

    QNetworkAccessManager *m_network = nullptr;
    update::UpdateService *m_service = nullptr;
    State m_state = Idle;
    std::optional<update::Release> m_release;
    std::optional<update::ReleaseAsset> m_asset;
    QString m_downloadedFile;
    QString m_error;
    qreal m_progress = 0;
    bool m_dismissed = false;
};

} // namespace iptvx::ui
