import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import "analytics.js" as AnalyticsJS

Drawer {
    signal aboutToDestroy
    required property Context context
    property real minimumContentWidth: 350
    property real preferredContentWidth: 0
    property bool deleteOnClose: false

    function accept() {
        self.deleteOnClose = true
        self.close()
    }

    function reject() {
        self.deleteOnClose = true
        self.close()
    }

    onClosed: {
        if (self.deleteOnClose) {
            self.aboutToDestroy()
            self.destroy()
        }
    }

    id: self
    clip: true
    height: parent.height
    edge: Qt.RightEdge
    interactive: self.visible
    topPadding: 60
    bottomPadding: 60
    leftPadding: 48
    rightPadding: 48

    contentWidth: Math.max(self.minimumContentWidth, self.preferredContentWidth)
    Behavior on contentWidth {
        SmoothedAnimation { velocity: 500 }
    }

    Overlay.modal: Rectangle {
        id: modal
        color: constants.c900
        FastBlur {
            anchors.fill: parent
            cached: true
            opacity: self.position
            radius: 64 * self.position
            source: ShaderEffectSource {
                sourceItem: ApplicationWindow.contentItem
                sourceRect {
                    x: 0
                    y: 0
                    width: modal.width
                    height: modal.height
                }
            }
        }
    }

    background: Rectangle {
        color: '#13161D'
        Rectangle {
            color: '#FFF'
            opacity: 0.1
            width: 1
            height: parent.height
        }
    }
}
