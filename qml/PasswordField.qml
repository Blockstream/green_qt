import QtQuick
import QtQuick.Controls

TextField {
    id: self
    echoMode: TextField.Password
    topPadding: 14
    bottomPadding: 13
    leftPadding: 15
    rightPadding: 64
    background: Rectangle {
        color: '#222226'
        radius: 5
        Rectangle {
            border.width: 2
            border.color: '#00B45A'
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
    font.pixelSize: 14
    font.weight: 500
    CircleButton {
        anchors.right: parent.right
        anchors.rightMargin: 15
        anchors.verticalCenter: parent.verticalCenter
        icon.source: self.echoMode === TextField.Password ? 'qrc:/svg2/eye_closed.svg' : 'qrc:/svg2/eye.svg'
        onClicked: self.echoMode = self.echoMode === TextField.Password ? TextInput.Normal : TextInput.Password
    }
}
