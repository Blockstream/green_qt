import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

TextField {
    id: self

    property string address_input

    Layout.fillWidth: true
    topPadding: 14
    bottomPadding: 13
    leftPadding: 15
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
    font.family: 'SF Compact Display'
    font.pixelSize: 14
    font.weight: 457

    onTextChanged: {
        parsePayment(text)
        self.address_input = 'paste'
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        spacing: 0
        ToolButton {
            activeFocusOnTab: false
            enabled: window.scannerAvailable && !scanner_popup.visible
            icon.source: 'qrc:/svg/qr.svg'
            icon.width: 16
            icon.height: 16
            onClicked: scanner_popup.open()
            ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
            ToolTip.text: qsTrId('id_scan_qr_code')
            ToolTip.visible: hovered
        }
        ToolButton {
            activeFocusOnTab: false
            icon.source: 'qrc:/svg/paste.svg'
            icon.width: 24
            icon.height: 24
            onClicked: {
                address_field.clear();
                address_field.paste();
                parsePayment(address_field.text)
                self.address_input = 'paste'
            }
            ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
            ToolTip.text: qsTrId('id_paste')
            ToolTip.visible: hovered
        }
    }
}
