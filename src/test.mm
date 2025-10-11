#include <QWindow>

#ifdef Q_OS_MAC
#import <Cocoa/Cocoa.h>

void dumpViews(NSView *v, int depth=0) {
    NSLog(@"%*s%@: frame=%@", depth*2, "", NSStringFromClass([v class]), NSStringFromRect([v frame]));
    for (NSView *s in [v subviews]) dumpViews(s, depth+1);
}

void addBlurToWindow(QWindow *window) {
    NSView *nsView = reinterpret_cast<NSView *>(window->winId());

    dumpViews(nsView);

    NSVisualEffectView *blurView = [[NSVisualEffectView alloc] initWithFrame:[nsView bounds]];
    [blurView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];

    [blurView setMaterial:NSVisualEffectMaterialUnderWindowBackground];
    [blurView setBlendingMode:NSVisualEffectBlendingModeBehindWindow];
    [blurView setState:NSVisualEffectStateActive];

    [nsView addSubview:blurView positioned:NSWindowBelow relativeTo:nil];
}
#endif
