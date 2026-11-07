// SPDX-License-Identifier: MIT
#include "update/UpdateInstaller.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QProcess>
#include <QStandardPaths>

using namespace Qt::StringLiterals;

namespace iptvx::update {

namespace {

// Writes a helper shell script next to the download and returns its path.
[[maybe_unused]] QString writeScript(const QString &directory, const QString &name, const QByteArray &body)
{
    const QString path = QDir(directory).filePath(name);
    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return {};
    file.write(body);
    file.close();
    file.setPermissions(QFile::ReadOwner | QFile::WriteOwner | QFile::ExeOwner);
    return path;
}

} // namespace

UpdateInstaller::Result UpdateInstaller::start(const QString &downloadedFile, QString *error)
{
    const QFileInfo download(downloadedFile);
    if (!download.exists()) {
        if (error)
            *error = QCoreApplication::translate("UpdateInstaller", "The downloaded update was not found.");
        return Result::Failed;
    }
    const QString pid = QString::number(QCoreApplication::applicationPid());

#if defined(Q_OS_MACOS)
    // .../IPTVX.app/Contents/MacOS → .../IPTVX.app
    QDir bundleDir(QCoreApplication::applicationDirPath());
    bundleDir.cdUp();
    bundleDir.cdUp();
    const QString bundle = bundleDir.absolutePath();
    const bool replaceable = bundle.endsWith(u".app"_s)
        && QFileInfo(QFileInfo(bundle).absolutePath()).isWritable();
    if (!replaceable) {
        QProcess::startDetached(u"/usr/bin/open"_s, { u"-R"_s, download.absoluteFilePath() });
        return Result::NeedsManual;
    }
    static const QByteArray script = R"SH(#!/bin/sh
# IPTVX self-update: $1 = pid to wait for, $2 = zip, $3 = installed bundle
pid="$1"; zip="$2"; bundle="$3"
while kill -0 "$pid" 2>/dev/null; do sleep 0.3; done
tmp="$(mktemp -d)" || exit 1
/usr/bin/ditto -x -k "$zip" "$tmp" || { /usr/bin/open -R "$zip"; exit 1; }
new="$(find "$tmp" -maxdepth 1 -name '*.app' | head -n 1)"
[ -n "$new" ] || { /usr/bin/open -R "$zip"; exit 1; }
/usr/bin/xattr -dr com.apple.quarantine "$new" 2>/dev/null
rm -rf "$bundle.previous"
if mv "$bundle" "$bundle.previous" && mv "$new" "$bundle"; then
    rm -rf "$bundle.previous" "$zip"
else
    [ -d "$bundle.previous" ] && [ ! -d "$bundle" ] && mv "$bundle.previous" "$bundle"
fi
rm -rf "$tmp"
/usr/bin/open "$bundle"
)SH";
    const QString helper = writeScript(download.absolutePath(), u"install-update.sh"_s, script);
    if (helper.isEmpty()
        || !QProcess::startDetached(u"/bin/sh"_s, { helper, pid, download.absoluteFilePath(), bundle })) {
        if (error)
            *error = QCoreApplication::translate("UpdateInstaller", "Could not start the updater.");
        return Result::Failed;
    }
    return Result::Started;

#elif defined(Q_OS_LINUX)
    QFile::setPermissions(download.absoluteFilePath(),
                          QFile::ReadOwner | QFile::WriteOwner | QFile::ExeOwner | QFile::ReadGroup
                              | QFile::ExeGroup | QFile::ReadOther | QFile::ExeOther);
    const QString running = qEnvironmentVariable("APPIMAGE"); // set by the AppImage runtime
    if (running.isEmpty() || !QFileInfo(QFileInfo(running).absolutePath()).isWritable()) {
        // Not running from an AppImage (e.g. a distro package or dev build):
        // just start the new AppImage.
        if (!QProcess::startDetached(download.absoluteFilePath(), {})) {
            if (error)
                *error = QCoreApplication::translate("UpdateInstaller", "Could not start the new version.");
            return Result::Failed;
        }
        return Result::Started;
    }
    static const QByteArray script = R"SH(#!/bin/sh
# IPTVX self-update: $1 = pid, $2 = new AppImage, $3 = running AppImage
pid="$1"; new="$2"; target="$3"
while kill -0 "$pid" 2>/dev/null; do sleep 0.3; done
chmod +x "$new"
if mv -f "$new" "$target"; then exec "$target"; else exec "$new"; fi
)SH";
    const QString helper = writeScript(download.absolutePath(), u"install-update.sh"_s, script);
    if (helper.isEmpty()
        || !QProcess::startDetached(u"/bin/sh"_s, { helper, pid, download.absoluteFilePath(), running })) {
        if (error)
            *error = QCoreApplication::translate("UpdateInstaller", "Could not start the updater.");
        return Result::Failed;
    }
    return Result::Started;

#elif defined(Q_OS_WIN)
    // Inno Setup installer (per-user, no UAC). /CLOSEAPPLICATIONS lets it
    // close us if we are still running; its [Run] entry relaunches IPTVX.
    if (!QProcess::startDetached(download.absoluteFilePath(),
                                 { u"/SILENT"_s, u"/SUPPRESSMSGBOXES"_s, u"/NORESTART"_s,
                                   u"/CLOSEAPPLICATIONS"_s })) {
        if (error)
            *error = QCoreApplication::translate("UpdateInstaller", "Could not start the installer.");
        return Result::Failed;
    }
    Q_UNUSED(pid)
    return Result::Started;

#else
    Q_UNUSED(pid)
    if (error)
        *error = QCoreApplication::translate("UpdateInstaller", "Automatic updates are not supported on this platform.");
    return Result::Failed;
#endif
}

} // namespace iptvx::update
