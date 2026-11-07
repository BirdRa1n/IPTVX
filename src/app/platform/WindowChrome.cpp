// SPDX-License-Identifier: MIT
// Non-macOS implementation: the native frame is used unchanged.
#include "platform/WindowChrome.h"

namespace iptvx::app {

QRectF styleWindowChrome(QWindow *)
{
    return {};
}

} // namespace iptvx::app
