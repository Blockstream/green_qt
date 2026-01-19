import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractButton {
    required property color fillColor
    required property color borderColor
    required property color textColor
    property real radius: 8
    property real borderWidth: 1
    property bool busy: false
    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }
    id: self
    focusPolicy: Qt.StrongFocus
    font.pixelSize: 16
    font.weight: 600
    padding: 16
    leftPadding: 16
    rightPadding: 16
    topPadding: 12
    bottomPadding: 12
    opacity: self.enabled ? 1 : 0.4
    background: Item {
        Rectangle {
            anchors.fill: parent
            border.color: '#00BCFF'
            border.width: 2
            color: 'transparent'
            radius: self.radius
            visible: self.visualFocus
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: self.visualFocus ? 4 : 0
            color: Qt.lighter(self.fillColor, self.enabled && self.hovered ? 1.1 : 1)
            border.color: Qt.lighter(self.borderColor, self.enabled && self.hovered ? 1.1 : 1)
            border.width: self.borderWidth
            radius: self.visualFocus ? self.radius - 4 : self.radius
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
                black: true
                height: 24
                indeterminate: self.busy
                width: 24
                x: 10
            }
        }
        HSpacer {
        }
    }
}
