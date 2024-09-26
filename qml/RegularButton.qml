import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractButton {
    property bool busy: false
    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }
    id: self
    focusPolicy: Qt.StrongFocus
    font.pixelSize: 16
    font.weight: 700
    padding: 16
    leftPadding: 16
    rightPadding: 16
    topPadding: 12
    bottomPadding: 12
    opacity: self.enabled ? 1 : 0.4
    background: Item {
        Rectangle {
            anchors.fill: parent
            border.width: 2
            border.color: '#00B45A'
            color: 'transparent'
            radius: 8
            visible: self.visualFocus
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: self.visualFocus ? 4 : 0
            color: Qt.alpha('#FFF', self.enabled && self.hovered ? 0.2 : 0)
            border.width: 1
            border.color: '#FFF'
            radius: self.visualFocus ? 4 : 8
        }
    }
    contentItem: RowLayout {
        spacing: image.visible ? 10 : 0
        HSpacer {
        }
        Image {
            id: image
            source: self.icon.source
            visible: image.status === Image.Ready
        }
        Label {
            font: self.font
            horizontalAlignment: Text.AlignHCenter
            text: self.text
            verticalAlignment: Text.AlignVCenter
        }
        Collapsible {
            property real _busy: self.busy ? 1 : 0
            Behavior on _busy {
                SmoothedAnimation {
                    velocity: 1
                }
            }
            id: collapsible
            animationVelocity: 200
            collapsed: collapsible._busy === 0
            horizontalCollapse: true
            verticalCollapse: false
            ProgressIndicator {
                x: 10
                width: 24
                height: 24
                indeterminate: self.busy
            }
        }
        HSpacer {
        }
    }
}
