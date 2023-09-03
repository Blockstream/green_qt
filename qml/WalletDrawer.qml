import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import "analytics.js" as AnalyticsJS

Drawer {
    required property Context context

    id: self
    clip: true
    height: parent.height
    edge: Qt.RightEdge
    interactive: true
    topPadding: 60
    bottomPadding: 60
    leftPadding: 48
    rightPadding: 48

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
