import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RegularButton {
    required property PinField target
    id: self
    focusPolicy: Qt.NoFocus
    icon.source: 'qrc:/svg2/hand.svg'
    text: 'Pin Pad'
    leftPadding: 13
    topPadding: 12
    bottomPadding: 12
    rightPadding: 13
    onClicked: collapsible.toggle()
    contentItem: ColumnLayout {
        spacing: 0
        RowLayout {
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
                font.weight: 700
                horizontalAlignment: Text.AlignHCenter
                text: self.text
                verticalAlignment: Text.AlignVCenter
            }
            HSpacer {
            }
        }
        Collapsible {
            Layout.alignment: Qt.AlignCenter
            id: collapsible
            animationVelocity: 300
            horizontalCollapse: true
            verticalCollapse: true
            collapsed: true
            contentWidth: pad.width
            contentHeight: 5 + pad.height
            GridLayout {
                id: pad
                anchors.horizontalCenter: parent.horizontalCenter
                columns: 3
                columnSpacing: 10
                rowSpacing: 10
                y: 5
                Repeater {
                    model: 9
                    RegularButton {
                        Layout.preferredWidth: 56
                        text: index + 1
                        onClicked: self.target.append(index + 1)
                    }
                }
                PadButton {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 56
                    icon.source: 'qrc:/svg2/x-square.svg'
                    onClicked: self.target.clear()
                }
                RegularButton {
                    Layout.preferredWidth: 56
                    text: '0'
                    onClicked: self.target.append(0)
                }
                PadButton {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 56
                    icon.source: 'qrc:/svg2/backspace.svg'
                    onClicked: self.target.remove()
                }
            }
        }
    }

     component PadButton: AbstractButton {
        id: self
        focusPolicy: Qt.NoFocus
        padding: 16
        leftPadding: 0
        rightPadding: 0
        topPadding: 0
        bottomPadding: 0
        opacity: self.enabled ? 1 : 0.4
        background: Rectangle {
            color: Qt.alpha('#FFF', self.enabled && self.hovered ? 0.2 : 0)
            border.width: 1
            border.color: '#FFF'
            radius: 8
            Rectangle {
                border.width: 2
                border.color: '#00B45A'
                color: 'transparent'
                radius: 12
                anchors.fill: parent
                anchors.margins: -4
                z: -1
                opacity: self.visualFocus ? 1 : 0
            }
        }
        contentItem: RowLayout {
            Image {
                Layout.alignment: Qt.AlignCenter
                source: self.icon.source
            }
        }
    }
}
