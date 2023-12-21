import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

TextField {
    property string address_input
    property var error
    Layout.fillWidth: true
    id: self
    topPadding: 18
    bottomPadding: 18
    leftPadding: 18
    rightPadding: options_layout.width + 18 + 10
    background: Rectangle {
        color: '#222226'
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

    // TODO move to call site, abstract in controllers
    /* onTextChanged: (text) => {
        const payment = WalletManager.parseUrl(text.trim())
        address_field.text = payment.address;
        if (payment.amount) {
            controller.amount = formatAmount(self.account, payment.amount * 100000000, false)
        }
        if (payment.message) {
            controller.memo = payment.message
        }
        self.address_input = 'paste'
    }
    */

    RowLayout {
        id: options_layout
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 18
        spacing: 10
        CircleButton {
            activeFocusOnTab: false
            enabled: scanner_popup.available && !scanner_popup.visible
            icon.source: 'qrc:/svg2/qrcode.svg'
            onClicked: scanner_popup.open()
            ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
            ToolTip.text: qsTrId('id_scan_qr_code')
            ToolTip.visible: hovered
        }
        CircleButton {
            activeFocusOnTab: false
            icon.source: 'qrc:/svg2/paste.svg'
            onClicked: {
                self.paste();
                self.address_input = 'paste'
            }
            ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
            ToolTip.text: qsTrId('id_paste')
            ToolTip.visible: hovered
        }
    }
    ScannerPopup {
        id: scanner_popup
        onCodeScanned: (code) => self.text = code //controller.parseAndUpdate(code)
    }
}
