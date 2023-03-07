import QtQuick
import QtQuick.Layouts

Loader {
    required property bool animated
    id: self
    focus: StackLayout.isCurrentItem
    opacity: self.active ? 1 : 0
    Behavior on opacity {
        enabled: self.animated
        OpacityAnimator {
        }
    }
    transform: Translate {
        x: self.active ? 0 : 32
        Behavior on x {
            enabled: self.animated
            SmoothedAnimation {
            }
        }
    }
}
