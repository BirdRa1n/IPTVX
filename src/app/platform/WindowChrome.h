// SPDX-License-Identifier: MIT
#pragma once

#include <QRectF>

class QWindow;

namespace iptvx::app {

/// Native window-chrome integration.
///
/// macOS: hides the title text, makes the title bar transparent and uses a
/// unified toolbar so the traffic-light buttons sit vertically centred in a
/// 52 pt bar, then returns their union rect in window coordinates (top-left
/// origin, device-independent pixels) so QML can align its own chrome.
///
/// Other platforms: no-op, returns an empty rect.
QRectF styleWindowChrome(QWindow *window);

} // namespace iptvx::app
