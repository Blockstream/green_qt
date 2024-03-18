import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractButton {
    property color fillColor: '#00B45A'
    property color borderColor: '#00B45A'
    property color textColor: '#FFFFFF'
    property bool busy: false
    id: self
    focusPolicy: Qt.StrongFocus
    padding: 16
    leftPadding: 16
    rightPadding: 16
    topPadding: 12
    bottomPadding: 12
    opacity: self.enabled ? 1 : 0.4
    background: Rectangle {
        color: Qt.lighter(self.fillColor, self.enabled && self.hovered ? 1.1 : 1)
        border.color: Qt.lighter(self.borderColor, self.enabled && self.hovered ? 1.1 : 1)
        radius: 8
        Rectangle {
            border.width: 2
            border.color: self.borderColor
            color: 'transparent'
            radius: 12
            anchors.fill: parent
            anchors.margins: -4
            z: -1
            opacity: self.visualFocus ? 1 : 0
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
            font.pixelSize: 16
            font.weight: 600
            color: self.textColor
            opacity: self.enabled ? 1.0 : 0.6
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
