#include <Cocoa/Cocoa.h>

#include <QWidget>

void removeTitlebarFromWindow(QWidget* window)
{
    NSView *nativeView = reinterpret_cast<NSView *>(window->winId());
    NSWindow* nativeWindow = [nativeView window];

    [nativeWindow setStyleMask:[nativeWindow styleMask] | NSWindowStyleMaskFullSizeContentView | NSWindowTitleHidden];
    [nativeWindow setTitlebarAppearsTransparent:YES];
    [nativeWindow setMovableByWindowBackground:NO];
}
