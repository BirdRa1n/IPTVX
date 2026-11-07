// SPDX-License-Identifier: MIT
#pragma once

#include <QString>

class QQmlApplicationEngine;

namespace iptvx::app {

/// Developer / agent tooling driven by environment variables.
///
/// | Variable               | Effect                                             |
/// |------------------------|----------------------------------------------------|
/// | IPTVX_SANDBOX=1        | Use an isolated profile (QStandardPaths test mode) |
/// | IPTVX_SEED_PLAYLIST=f  | Add the M3U file `f` when the library is empty     |
/// | IPTVX_PAGE=live        | Open a page on start (home, live, settings)        |
/// | IPTVX_APPEARANCE=dark  | Force light / dark appearance                      |
/// | IPTVX_PALETTE=query    | Open the command palette with `query` typed in     |
/// | IPTVX_SCREENSHOT=p.png | Save a window capture after IPTVX_SCREENSHOT_DELAY |
/// |                        | ms (default 2500) and quit                         |
///
/// Setting IPTVX_SCREENSHOT or IPTVX_SEED_PLAYLIST implies IPTVX_SANDBOX, so
/// automated runs never touch the user's real library.
struct DevOptions
{
    bool sandbox = false;
    QString seedPlaylist;
    QString page;
    QString appearance;
    QString palette;
    bool openPalette = false;
    QString screenshotPath;
    int screenshotDelayMs = 2500;

    static DevOptions fromEnvironment();
    void applyEarly() const;
    void applyAfterLoad(QQmlApplicationEngine &engine) const;
};

} // namespace iptvx::app
