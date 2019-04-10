import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

ColumnLayout {
//    property alias account: receive_address.account
    property alias address: receive_address.address
    property alias amount: amount_field.amount
    property alias message: message_field.text

    function url(address, amount, message) {
        var parts = []
        if (amount && amount > 0) parts.push('amount=' + amount)
        if (message) parts.push('message=' + message)
        if (parts.length === 0) return address
        return 'bitcoin:' + address + '?' + parts.join('&')
    }

    property var bla: account ? account : null
    spacing: 16

    ReceiveAddress {
        id: receive_address
        account: bla
    }

    AmountConverter {
        id: converter
        wallet: account ? account.wallet : null
        input: ({ btc: amount ? amount : '0' })
    }

    RowLayout {
        spacing: 8

        FlatButton {
            text: qsTr('NEW')
            enabled: !receive_address.generating
            onClicked: receive_address.generate()
        }

        TextField {
            id: address_field
            Layout.fillWidth: true
            text: address
            readOnly: true
            horizontalAlignment: Label.AlignHCenter
            verticalAlignment: Label.AlignVCenter
        }

        FlatButton {
            text: qsTr('COPY')
            onClicked: {
                address_field.selectAll()
                address_field.copy()
            }
        }
    }

    Item {
        Layout.minimumHeight: 128
        Layout.maximumHeight: 128
        Layout.minimumWidth: 256
        Layout.fillWidth: true
        Layout.fillHeight: true

        QRCode {
            id: qrcode
            anchors.fill: parent
            text: url(address, amount, message)
            opacity: receive_address.generating ? 0 : 1.0

            Behavior on opacity {
                OpacityAnimator { duration: 200 }
            }
        }

        BusyIndicator {
            anchors.centerIn: parent
            visible: receive_address.generating
        }
    }

    Label {
        Layout.fillWidth: true
        wrapMode: TextInput.WrapAnywhere
        text: qrcode.text
        Layout.maximumWidth: parent.width
        horizontalAlignment: Label.AlignHCenter
        verticalAlignment: Label.AlignVCenter
        font.pixelSize: address_field.font.pixelSize * 0.75
        enabled: false
    }

    RowLayout {
        AmountField {
            id: amount_field
            Layout.fillWidth: true
            currency: 'BTC'
            label: qsTr('AMOUNT')
        }

        Item {
            Layout.minimumWidth: 16
        }

        AmountField {
            Layout.fillWidth: true
            readOnly: true
            amount: converter.valid ? converter.output.fiat : ''
            currency: converter.valid ? converter.output.fiat_currency : ''
        }
    }

    TextField {
        id: message_field
        Layout.fillWidth: true
        placeholderText: qsTr('DESCRIPTION')
    }
}
