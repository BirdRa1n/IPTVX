// SPDX-License-Identifier: MIT
#include "DevTools.h"

#include "Library.h"

#include <QCoreApplication>
#include <QDir>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QStandardPaths>
#include <QTimer>
#include <QUrl>

using namespace Qt::StringLiterals;

namespace iptvx::app {

DevOptions DevOptions::fromEnvironment()
{
    DevOptions o;
    o.seedPlaylist = qEnvironmentVariable("IPTVX_SEED_PLAYLIST");
    o.page = qEnvironmentVariable("IPTVX_PAGE");
    o.appearance = qEnvironmentVariable("IPTVX_APPEARANCE");
    o.screenshotPath = qEnvironmentVariable("IPTVX_SCREENSHOT");
    bool ok = false;
    const int delay = qEnvironmentVariableIntValue("IPTVX_SCREENSHOT_DELAY", &ok);
    if (ok && delay >= 0)
        o.screenshotDelayMs = delay;
    o.sandbox = qEnvironmentVariableIntValue("IPTVX_SANDBOX") != 0 || !o.seedPlaylist.isEmpty()
        || !o.screenshotPath.isEmpty();
    return o;
}

void DevOptions::applyEarly() const
{
    if (!sandbox)
        return;
    // Redirects AppData/Cache/Config to ~/.qttest/… and starts clean.
    QStandardPaths::setTestModeEnabled(true);
    for (auto location : { QStandardPaths::AppDataLocation, QStandardPaths::CacheLocation,
                           QStandardPaths::AppConfigLocation }) {
        QDir(QStandardPaths::writableLocation(location)).removeRecursively();
    }
}

void DevOptions::applyAfterLoad(QQmlApplicationEngine &engine) const
{
    auto *library = engine.singletonInstance<iptvx::ui::Library *>("IPTVX.UI", "Library");
    if (library && !seedPlaylist.isEmpty() && library->sources()->count() == 0)
        library->addM3uFile(QString(), QUrl::fromLocalFile(QDir(seedPlaylist).absolutePath()));

    QObject *session = engine.singletonInstance<QObject *>("IPTVX.UI", "Session");
    if (session && !appearance.isEmpty())
        session->setProperty("appearance", appearance);
    if (session && !page.isEmpty())
        session->setProperty("page", page);

    if (screenshotPath.isEmpty() || engine.rootObjects().isEmpty())
        return;
    auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().constFirst());
    if (!window)
        return;
    const QString path = screenshotPath;
    QTimer::singleShot(screenshotDelayMs, window, [window, path] {
        const bool saved = window->grabWindow().save(path);
        qInfo("IPTVX screenshot %s: %s", saved ? "saved" : "FAILED", qPrintable(path));
        QCoreApplication::exit(saved ? 0 : 1);
    });
}

} // namespace iptvx::app
