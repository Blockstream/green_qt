import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    required property Context context
    readonly property Flickable flickable: {
        let flickable = parent
        while (flickable && !(flickable instanceof Flickable)) {
            flickable = flickable.parent
        }
        return flickable
    }
    property alias headerItem: header_pane.contentItem
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
    header: Pane {
        id: header_pane
        background: null
        topPadding: 16
        bottomPadding: 2
        padding: 0
    }
    footer: Item {
        implicitHeight: 16
    }
    Behavior on opacity {
        SmoothedAnimation {
            velocity: 4
        }
    }
}
