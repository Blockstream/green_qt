import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

TextField {
    signal codeScanned(string code)
    property string address_input
    property var error
    Layout.fillWidth: true
    id: self
    topPadding: 18
    bottomPadding: 18
    leftPadding: self.text.length > 0 ? 60 : 18
    rightPadding: (options_layout.visible ? options_layout.width + 10 : 0) + 18
    background: Rectangle {
        color: Qt.lighter('#222226', !self.readOnly && self.hovered ? 1.2 : 1)
        radius: 5
        border.width: !!self.error ? 2 : 0
        border.color: '#C91D36'
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
        focusPolicy: Qt.NoFocus
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 18
        visible: !self.readOnly && self.text !== ''
        icon.source: 'qrc:/svg2/x-circle.svg'
        onClicked: self.clear()
    }
    RowLayout {
        id: options_layout
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 18
        spacing: 10
        visible: !self.readOnly
        CircleButton {
            activeFocusOnTab: false
            enabled: scanner_popup.available && !scanner_popup.visible
            icon.source: 'qrc:/svg2/qrcode.svg'
            onClicked: scanner_popup.open()
        }
        CircleButton {
            activeFocusOnTab: false
            icon.source: 'qrc:/svg2/paste.svg'
            onClicked: {
                self.paste();
                self.address_input = 'paste'
            }
        }
    }
    ScannerPopup {
        id: scanner_popup
        onCodeScanned: (code) => {
            self.address_input = 'scan'
            self.codeScanned(code)
        }
    }
}
