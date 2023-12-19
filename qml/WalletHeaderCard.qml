import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractButton {
    required property Context context
    readonly property Flickable flickable: {
        let flickable = parent
        while (flickable && !(flickable instanceof Flickable)) {
            flickable = flickable.parent
        }
        return flickable
    }
    Layout.fillHeight: true
    Layout.minimumWidth: 180
    id: self
    background: null
    padding: 0
    opacity: {
        if (!self.flickable) return 1
        if ((self.x - self.flickable.contentX) < 0) return 0.2
        if ((self.x - self.flickable.contentX + self.width) > self.flickable.width) return 0.2
        return 1
    }
    layer.enabled: true
    Behavior on opacity {
        SmoothedAnimation {
            velocity: 4
        }
    }
}
