// SPDX-License-Identifier: MIT
#include "Updates.h"

#include "update/UpdateInstaller.h"
#include "update/UpdateService.h"

#include <QCoreApplication>
#include <QDesktopServices>
#include <QNetworkAccessManager>
#include <QSettings>
#include <QStandardPaths>
#include <QTimer>

using namespace Qt::StringLiterals;

#ifndef IPTVX_UPDATE_REPO
#define IPTVX_UPDATE_REPO "BirdRa1n/IPTVX"
#endif

namespace iptvx::ui {

namespace {
const QString kAutoCheckKey = u"updates/autoCheck"_s;
}

Updates::Updates(QObject *parent)
    : QObject(parent)
    , m_network(new QNetworkAccessManager(this))
{
    m_service = new update::UpdateService(m_network, QStringLiteral(IPTVX_UPDATE_REPO), currentVersion(), this);

    connect(m_service, &update::UpdateService::updateAvailable, this,
            [this](const update::Release &release, const std::optional<update::ReleaseAsset> &asset) {
                m_release = release;
                m_asset = asset;
                emit releaseChanged();
                setDismissed(false);
                setState(Available);
            });
    connect(m_service, &update::UpdateService::upToDate, this, [this](const QString &) { setState(UpToDate); });
    connect(m_service, &update::UpdateService::checkFailed, this,
            [this](const QString &error) { setState(Failed, error); });
    connect(m_service, &update::UpdateService::downloadProgress, this, [this](qint64 received, qint64 total) {
        if (total <= 0 && m_asset)
            total = m_asset->size;
        m_progress = total > 0 ? qreal(received) / qreal(total) : 0;
        emit progressChanged();
    });
    connect(m_service, &update::UpdateService::downloaded, this, [this](const QString &path) {
        m_downloadedFile = path;
        m_progress = 1;
        emit progressChanged();
        setState(ReadyToInstall);
    });
    connect(m_service, &update::UpdateService::downloadFailed, this,
            [this](const QString &error) { setState(Failed, error); });
}

Updates::~Updates() = default;

QString Updates::currentVersion() const
{
    return QCoreApplication::applicationVersion();
}

QUrl Updates::releaseUrl() const
{
    if (m_release && m_release->pageUrl.isValid())
        return m_release->pageUrl;
    return QUrl(u"https://github.com/%1/releases"_s.arg(QStringLiteral(IPTVX_UPDATE_REPO)));
}

QString Updates::platformLabel() const
{
    const update::Platform p = update::Platform::current();
    switch (p.os) {
    case update::Platform::Os::MacOS:
        return p.arch == u"arm64"_s ? tr("macOS (Apple silicon)") : tr("macOS (Intel)");
    case update::Platform::Os::Linux:
        return p.arch == u"aarch64"_s ? tr("Linux (ARM64)") : tr("Linux (x86-64)");
    case update::Platform::Os::Windows:
        return tr("Windows (x64)");
    case update::Platform::Os::Other:
        break;
    }
    return tr("Unknown platform");
}

bool Updates::autoCheck() const
{
    return QSettings().value(kAutoCheckKey, true).toBool();
}

void Updates::setAutoCheck(bool enabled)
{
    if (enabled == autoCheck())
        return;
    QSettings().setValue(kAutoCheckKey, enabled);
    emit autoCheckChanged();
}

void Updates::setDismissed(bool dismissed)
{
    if (dismissed == m_dismissed)
        return;
    m_dismissed = dismissed;
    emit dismissedChanged();
}

void Updates::setState(State state, const QString &error)
{
    if (state == m_state && error == m_error)
        return;
    m_state = state;
    m_error = error;
    emit stateChanged();
}

void Updates::checkOnStartup()
{
    if (!autoCheck() || qEnvironmentVariableIsSet("IPTVX_NO_UPDATE_CHECK"))
        return;
    // Let the UI settle and the catalog load first.
    QTimer::singleShot(4000, this, &Updates::check);
}

void Updates::check()
{
    if (m_state == Checking || m_state == Downloading)
        return;
    setState(Checking);
    m_service->check();
}

void Updates::download()
{
    if (!m_asset || m_state == Downloading)
        return;
    m_progress = 0;
    emit progressChanged();
    setState(Downloading);
    m_service->download(*m_asset,
                        QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + u"/updates"_s);
}

void Updates::cancelDownload()
{
    m_service->cancel();
    setState(Available);
}

void Updates::installAndRestart()
{
    if (m_downloadedFile.isEmpty())
        return;
    QString error;
    switch (update::UpdateInstaller::start(m_downloadedFile, &error)) {
    case update::UpdateInstaller::Result::Started:
        QCoreApplication::quit();
        return;
    case update::UpdateInstaller::Result::NeedsManual:
        setState(Failed, tr("IPTVX cannot replace itself in this folder. The update was opened so you can install it."));
        return;
    case update::UpdateInstaller::Result::Failed:
        setState(Failed, error);
        return;
    }
}

void Updates::previewRelease(const QString &version)
{
    update::Release release;
    release.tag = u"v"_s + version;
    release.version = version;
    release.notes = u"## What's new\n\n- Faster channel search\n- Mini player remembers its corner\n- Bug fixes and performance improvements"_s;
    m_release = release;
    update::ReleaseAsset asset;
    asset.name = u"IPTVX-%1-%2"_s.arg(version, update::Platform::current().assetSuffix());
    asset.size = 48 * 1024 * 1024;
    m_asset = asset;
    emit releaseChanged();
    setDismissed(false);
    setState(Available);
}

void Updates::openReleasePage() const
{
    QDesktopServices::openUrl(releaseUrl());
}

} // namespace iptvx::ui
