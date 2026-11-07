// SPDX-License-Identifier: MIT
#pragma once

#include <QString>

namespace iptvx::update {

/// Hands a downloaded release asset to the platform and relaunches IPTVX.
///
/// | Platform | Asset                      | What happens                              |
/// |----------|----------------------------|-------------------------------------------|
/// | macOS    | `…-macos-<arch>.zip`       | a detached script waits for IPTVX to quit,|
/// |          |                            | unpacks the .app, swaps it in place and   |
/// |          |                            | reopens it                                 |
/// | Linux    | `…-linux-<arch>.AppImage`  | replaces the running AppImage ($APPIMAGE) |
/// |          |                            | and starts it; otherwise starts the new   |
/// |          |                            | AppImage from the download folder         |
/// | Windows  | `…-windows-x64-setup.exe`  | runs the per-user installer silently; it  |
/// |          |                            | relaunches IPTVX when done                |
///
/// After a successful start() the caller must quit the application.
class UpdateInstaller
{
public:
    enum class Result {
        Started,       ///< Installer launched; quit the app now.
        NeedsManual,   ///< Cannot replace in place; the file was revealed instead.
        Failed,
    };

    static Result start(const QString &downloadedFile, QString *error = nullptr);
};

} // namespace iptvx::update
