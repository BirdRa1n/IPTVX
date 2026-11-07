// SPDX-License-Identifier: MIT
// Non-macOS implementation: the native frame is used unchanged.
#include "platform/WindowChrome.h"

namespace iptvx::app {

QRectF styleWindowChrome(QWindow *)
{
    return {};
}

qint64 nativeWindowNumber(QWindow *)
{
    return 0;
}

} // namespace iptvx::app
