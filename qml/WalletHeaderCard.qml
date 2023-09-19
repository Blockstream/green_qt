import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractButton {
    required property Context context

    Layout.fillHeight: true
    id: self
    padding: 0
    opacity: {
        let flickable = parent
        while (flickable && !(flickable instanceof Flickable)) {
            flickable = flickable.parent
        }
        if (!flickable) return 1
        if ((self.x - flickable.contentX) < 0) return 0.2
        if ((self.x - flickable.contentX + self.width + 16) > flickable.width) return 0.1
        return 1
    }
    Behavior on opacity {
        SmoothedAnimation {
            velocity: 4
        }
    }
}
