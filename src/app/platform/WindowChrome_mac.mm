// SPDX-License-Identifier: MIT
#include "platform/WindowChrome.h"

#include <QWindow>

#import <AppKit/AppKit.h>

namespace iptvx::app {

QRectF styleWindowChrome(QWindow *window)
{
    if (!window)
        return {};
    auto *view = reinterpret_cast<NSView *>(window->winId());
    NSWindow *nsWindow = view.window;
    if (!nsWindow)
        return {};

    nsWindow.titleVisibility = NSWindowTitleHidden;
    nsWindow.titlebarAppearsTransparent = YES;
    nsWindow.styleMask |= NSWindowStyleMaskFullSizeContentView;

    // An empty unified toolbar enlarges the title bar to the standard 52 pt
    // and centres the traffic lights in it, like native macOS apps.
    if (!nsWindow.toolbar) {
        NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"io.github.birdra1n.iptvx.toolbar"];
        nsWindow.toolbar = toolbar;

        // In full screen AppKit keeps the toolbar as an opaque strip above
        // the content (the traffic lights are hidden there anyway), which
        // would cover the app's own top bar. Hide it while full screen.
        NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
        [center addObserverForName:NSWindowWillEnterFullScreenNotification
                            object:nsWindow
                             queue:nil
                        usingBlock:^(NSNotification *note) {
                            static_cast<NSWindow *>(note.object).toolbar.visible = NO;
                        }];
        [center addObserverForName:NSWindowDidExitFullScreenNotification
                            object:nsWindow
                             queue:nil
                        usingBlock:^(NSNotification *note) {
                            static_cast<NSWindow *>(note.object).toolbar.visible = YES;
                        }];
    }
    nsWindow.toolbarStyle = NSWindowToolbarStyleUnified;
    nsWindow.titlebarSeparatorStyle = NSTitlebarSeparatorStyleNone; // QML draws its own hairline
    [nsWindow.contentView layoutSubtreeIfNeeded];
    [nsWindow layoutIfNeeded];

    NSRect controls = NSZeroRect;
    for (NSWindowButton kind : { NSWindowCloseButton, NSWindowMiniaturizeButton, NSWindowZoomButton }) {
        NSButton *button = [nsWindow standardWindowButton:kind];
        if (!button || button.hidden)
            continue;
        const NSRect inWindow = [button convertRect:button.bounds toView:nil];
        controls = NSIsEmptyRect(controls) ? inWindow : NSUnionRect(controls, inWindow);
    }
    if (NSIsEmptyRect(controls))
        return {};

    // AppKit window coordinates have a bottom-left origin.
    const CGFloat height = nsWindow.contentView.bounds.size.height;
    return QRectF(controls.origin.x, height - NSMaxY(controls), controls.size.width, controls.size.height);
}

} // namespace iptvx::app
