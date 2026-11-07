// SPDX-License-Identifier: MIT
#include "DevTools.h"

#include "Library.h"
#include "platform/WindowChrome.h"

#include <QCoreApplication>
#include <QDir>
#include <QQmlApplicationEngine>
#include <QPainter>
#include <QPainterPath>
#include <QProcess>
#include <QQuickWindow>
#include <QSettings>
#include <QStandardPaths>
#include <QTimer>
#include <QUrl>

using namespace Qt::StringLiterals;

namespace iptvx::app {

namespace {

// Composites a macOS-style window frame around a content grab: rounded
// corners, hairline border, soft shadow and the traffic lights drawn at the
// position measured from the real window (Main.titleBarControls). Used for
// documentation captures when `screencapture` is not permitted.
QImage frameLikeMacOS(const QImage &content, qreal dpr, const QRectF &controls)
{
    const qreal radius = 16 * dpr;
    const int pad = int(56 * dpr);
    QImage out(content.width() + 2 * pad, content.height() + 2 * pad, QImage::Format_ARGB32_Premultiplied);
    out.fill(Qt::transparent);
    QPainter p(&out);
    p.setRenderHint(QPainter::Antialiasing);

    const QRectF win(pad, pad, content.width(), content.height());

    // Shadow: layered translucent rounded rects, offset downwards.
    for (int i = 24; i >= 1; --i) {
        const qreal grow = i * 1.6 * dpr;
        QPainterPath path;
        path.addRoundedRect(win.adjusted(-grow, -grow * 0.6, grow, grow * 1.4).translated(0, 10 * dpr),
                            radius + grow, radius + grow);
        p.fillPath(path, QColor(0, 0, 0, int(5 + (24 - i) * 0.35)));
    }

    QPainterPath clip;
    clip.addRoundedRect(win, radius, radius);
    p.save();
    p.setClipPath(clip);
    p.drawImage(win.topLeft(), content);
    p.restore();
    p.setPen(QPen(QColor(0, 0, 0, 90), 1.0 * dpr));
    p.drawPath(clip);
    QPainterPath inner;
    inner.addRoundedRect(win.adjusted(dpr, dpr, -dpr, -dpr), radius - dpr, radius - dpr);
    p.setPen(QPen(QColor(255, 255, 255, 28), 1.0 * dpr));
    p.drawPath(inner);

    if (controls.width() > 0) {
        // Three 12 pt buttons, evenly spread over the measured rect.
        const QColor fills[] = { QColor(0xFF5F57), QColor(0xFEBC2E), QColor(0x28C840) };
        const QColor rims[] = { QColor(0xE0443E), QColor(0xDEA123), QColor(0x1AAB29) };
        const qreal d = 12 * dpr;
        const qreal step = (controls.width() - controls.height()) / 2;
        for (int i = 0; i < 3; ++i) {
            const QPointF c(win.x() + (controls.x() + controls.height() / 2 + i * step) * dpr,
                            win.y() + (controls.y() + controls.height() / 2) * dpr);
            p.setPen(QPen(rims[i], 0.6 * dpr));
            p.setBrush(fills[i]);
            p.drawEllipse(c, d / 2, d / 2);
        }
    }
    return out;
}

} // namespace

DevOptions DevOptions::fromEnvironment()
{
    DevOptions o;
    o.seedPlaylist = qEnvironmentVariable("IPTVX_SEED_PLAYLIST");
    o.page = qEnvironmentVariable("IPTVX_PAGE");
    o.appearance = qEnvironmentVariable("IPTVX_APPEARANCE");
    o.openPalette = qEnvironmentVariableIsSet("IPTVX_PALETTE");
    o.palette = qEnvironmentVariable("IPTVX_PALETTE");
    o.playNumber = qEnvironmentVariableIntValue("IPTVX_PLAY");
    o.nativeScreenshot = qEnvironmentVariableIntValue("IPTVX_SCREENSHOT_NATIVE") != 0;
    o.sheet = qEnvironmentVariable("IPTVX_SHEET");
    if (const QStringList wh = qEnvironmentVariable("IPTVX_WINDOW_SIZE").split(u'x'); wh.size() == 2)
        o.windowSize = QSize(wh[0].toInt(), wh[1].toInt());
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
    // QSettings does not follow QStandardPaths test mode (macOS writes to
    // ~/Library/Preferences, Windows to the registry). Redirect it to an INI
    // file inside the sandbox so preferences never leak into the real profile.
    QSettings::setDefaultFormat(QSettings::IniFormat);
    QSettings::setPath(QSettings::IniFormat, QSettings::UserScope,
                       QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation));
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

    if (session && playNumber > 0) {
        const int number = playNumber;
        QTimer::singleShot(800, session, [session, number] {
            QMetaObject::invokeMethod(session, "playNumber", Q_ARG(QVariant, number));
        });
    }

    if (openPalette && !engine.rootObjects().isEmpty()) {
        const QString query = palette;
        // Wait for the seeded source to load before typing the query.
        QTimer::singleShot(800, engine.rootObjects().constFirst(), [&engine, query] {
            QObject *popup = engine.rootObjects().constFirst()->findChild<QObject *>(u"commandPalette"_s);
            if (!popup)
                return;
            QMetaObject::invokeMethod(popup, "open");
            if (QObject *field = popup->findChild<QObject *>(u"paletteQuery"_s))
                field->setProperty("text", query);
        });
    }

    auto *window = engine.rootObjects().isEmpty()
        ? nullptr : qobject_cast<QQuickWindow *>(engine.rootObjects().constFirst());
    if (!window)
        return;

    if (windowSize.isValid())
        window->resize(windowSize);

    if (sheet == u"add"_s) {
        QTimer::singleShot(600, window, [window] {
            if (QObject *popup = window->findChild<QObject *>(u"addSourceSheet"_s))
                QMetaObject::invokeMethod(popup, "open");
        });
    }

    if (screenshotPath.isEmpty())
        return;
    const QString path = screenshotPath;
    const bool native = nativeScreenshot;
    QTimer::singleShot(screenshotDelayMs, window, [window, path, native] {
        bool saved = false;
        const qint64 id = native ? iptvx::app::nativeWindowNumber(window) : 0;
        if (id > 0) {
            // Includes the native frame: traffic lights, rounded corners and
            // shadow. Needs the Screen Recording permission on macOS.
            window->raise();
            window->requestActivate();
            saved = QProcess::execute(u"screencapture"_s,
                                      { u"-x"_s, u"-l"_s, QString::number(id), path }) == 0;
            if (!saved) {
                qInfo("IPTVX: screencapture not permitted (Screen Recording); compositing the frame");
                saved = frameLikeMacOS(window->grabWindow(), window->devicePixelRatio(),
                                       window->property("titleBarControls").toRectF())
                            .save(path);
            }
        } else {
            saved = window->grabWindow().save(path);
        }
        qInfo("IPTVX screenshot %s: %s", saved ? "saved" : "FAILED", qPrintable(path));
        QCoreApplication::exit(saved ? 0 : 1);
    });
}

} // namespace iptvx::app
