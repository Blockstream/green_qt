#include <Cocoa/Cocoa.h>

#include <QWindow>

void removeTitlebarFromWindow(QWindow* window)
{
    NSView *nativeView = reinterpret_cast<NSView *>(window->winId());
    NSWindow* nativeWindow = [nativeView window];

    [nativeWindow setStyleMask:[nativeWindow styleMask] | NSWindowStyleMaskFullSizeContentView | NSWindowTitleHidden];
    [nativeWindow setTitlebarAppearsTransparent:YES];
    [nativeWindow setMovableByWindowBackground:NO];
}
