import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

ColumnLayout {
    property alias address: receive_address.address
    property var amount: parseAmount(amount_field.text)

    function url(address, amount) {
        var parts = []
        if (amount && amount > 0) parts.push('amount=' + amount)
        if (parts.length === 0) return address
        return 'bitcoin:' + address + '?' + parts.join('&')
    }

    function copyAddress() {
        if (receive_address.generating) return
        receive_address.copyToClipboard()
        address_field.ToolTip.show(qsTr('id_address_copied_to_clipboard'), 1000)
    }

    spacing: 16

    ReceiveAddress {
        id: receive_address

        Binding on account {
            value: account
        }
    }

    RowLayout {
        SectionLabel {
            text: qsTrId('id_scan_to_send_here')
            Layout.fillWidth: true
        }
        ToolButton {
            icon.source: 'assets/svg/refresh.svg'
            icon.width: 16
            icon.height: 16
            onClicked: receive_address.generate()
        }
    }

    QRCode {
        id: qrcode
        opacity: receive_address.generating ? 0 : 1.0
        text: url(address, parseAmount(amount_field.text) / 100000000)
        Layout.alignment: Qt.AlignHCenter
        Behavior on opacity {
            OpacityAnimator { duration: 200 }
        }
        Rectangle {
            anchors.centerIn: parent
            border.width: 1
            border.color: '#00B45E'
            color: '#1000B45E'
            width: parent.height + 16
            height: width
            z: -1
        }
    }

    SectionLabel {
        text: qsTrId('id_address')
    }

    RowLayout {
        Label {
            id: address_field
            text: receive_address.address
            horizontalAlignment: Label.AlignHCenter
            verticalAlignment: Label.AlignVCenter
            Layout.fillWidth: true
            Layout.minimumWidth: 400
        }
        ToolButton {
            icon.source: 'assets/svg/copy_to_clipboard.svg'
            icon.width: 16
            icon.height: 16
            onClicked: copyAddress()
        }
    }

    SectionLabel {
        text: qsTrId('id_add_amount_optional')
    }
    RowLayout {
        TextField {
            id: amount_field
            horizontalAlignment: TextField.AlignRight
            rightPadding: unit.width + 8
            Layout.fillWidth: true
            Label {
                id: unit
                anchors.right: parent.right
                anchors.baseline: parent.baseline
                text: (wallet.network.liquid ? 'L-'+wallet.settings.unit : wallet.settings.unit) +
                      ' ≈ ' + formatFiat(parseAmount(amount_field.text))
            }
        }
    }
}
