import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

TTextField {
    signal cleared
    signal codeScanned(string code)
    property string address_input
    Layout.fillWidth: true
    id: self
    topPadding: 18
    bottomPadding: 18
    leftPadding: !self.readOnly && self.text.length > 0 ? 60 : 18
    rightPadding: (options_layout.visible ? options_layout.width + 10 : 0) + 18
    CircleButton {
        focusPolicy: Qt.NoFocus
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 18
        visible: !self.readOnly && self.text.length > 0
        icon.source: 'qrc:/svg2/x-circle.svg'
        onClicked: {
            self.clear()
            self.cleared()
        }
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
