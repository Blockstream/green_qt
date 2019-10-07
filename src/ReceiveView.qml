import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

ColumnLayout {
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

    spacing: 16

    ReceiveAddress {
        id: receive_address

        Binding on account {
            value: account
        }
    }

    AmountConverter {
        id: converter
        wallet: account ? account.wallet : null
        input: ({ btc: amount ? amount : '0' })
    }

    Label {
        text: 'SCAN TO SEND HERE'
        Layout.alignment: Qt.AlignHCenter

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

            MouseArea {
                enabled: !receive_address.generating
                anchors.fill: parent
                onClicked: receive_address.generate()
            }

            Rectangle {
                border.width: 2
                border.color: 'green'
                color: 'transparent'
                anchors.centerIn: parent
                width: parent.height + 6
                height: width
            }

        }

        BusyIndicator {
            anchors.centerIn: parent
            visible: receive_address.generating
        }
    }

    Label {
        text: qsTr('id_address')
    }

    TextField {
        id: address_field
        Layout.fillWidth: true
        text: address
        readOnly: true
        horizontalAlignment: Label.AlignHCenter
        verticalAlignment: Label.AlignVCenter
        MouseArea {
            anchors.fill: parent
            onClicked: {
                address_field.selectAll()
                address_field.copy()
            }
        }
    }

    AmountField {
        id: amount_field
        Layout.fillWidth: true
        currency: 'BTC'
        label: qsTr('id_amount')
    }

    TextField {
        id: message_field
        Layout.fillWidth: true
        placeholderText: qsTr('id_memo')
    }
}
