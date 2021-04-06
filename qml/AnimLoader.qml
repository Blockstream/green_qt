import QtQuick 2.15

Loader {
    required property bool animated
    id: self
    opacity: self.active ? 1 : 0
    Behavior on opacity {
        enabled: self.animated
        OpacityAnimator {
        }
    }
    transform: Translate {
        x: self.active ? 0 : 64
        Behavior on x {
            enabled: self.animated
            SmoothedAnimation {
            }
        }
    }
}
