import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

TextField {
    required property Network network
    Layout.fillWidth: true
    id: self
    topPadding: 14
    bottomPadding: 13
    leftPadding: 15
    rightPadding: 15 + options_layout.width + 10    
    font.pixelSize: 14
    font.weight: 500
    wrapMode: TextEdit.Wrap
    background: Rectangle {
        color: Qt.lighter('#222226', self.hovered ? 1.2 : 1)
        radius: 5
        Rectangle {
            border.width: 2
            border.color: '#00BCFF'
            color: 'transparent'
            radius: 9
            anchors.fill: parent
            anchors.margins: -4
            z: -1
            opacity: {
                if (self.activeFocus) {
                    switch (self.focusReason) {
                    case Qt.TabFocusReason:
                    case Qt.BacktabFocusReason:
                    case Qt.ShortcutFocusReason:
                        return 1
                    }
                }
                return 0
            }
        }
    }
    validator: XPubValidator {
        network: self.network
    }
    Row {
        id: options_layout
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 15
        spacing: 0
        CircleButton {
            activeFocusOnTab: false
            icon.source: 'qrc:/svg2/paste.svg'
            onClicked: {
                self.paste();
            }
        }
    }
}
