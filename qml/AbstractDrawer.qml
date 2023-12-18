import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Drawer {
    property real minimumContentWidth: 350
    property real preferredContentWidth: 0

    id: self
    clip: true
    height: parent.height
    interactive: self.visible
    topPadding: 30
    bottomPadding: 30
    leftPadding: 32 + self.leftMargin
    rightPadding: 32

    contentWidth: Math.max(self.minimumContentWidth, self.preferredContentWidth)
    Behavior on contentWidth {
        SmoothedAnimation {
            velocity: 500
        }
    }

    Overlay.modal: Rectangle {
        id: modal
        color: '#080B0E'
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

    Overlay.modeless: Rectangle {
        id: modeless
        color: '#080B0E'
        FastBlur {
            anchors.fill: parent
            cached: true
            opacity: self.position
            radius: 32 * self.position
            source: ShaderEffectSource {
                sourceItem: ApplicationWindow.contentItem
                sourceRect {
                    x: 0
                    y: 0
                    width: modeless.width
                    height: modeless.height
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
            x: self.edge === Qt.RightEdge ? 0 : parent.width - 1
        }
    }
}
