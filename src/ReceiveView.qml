import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

ColumnLayout {
    property alias address: receive_address.address
    property alias amount: amount_field.text

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

    Page {
        header: RowLayout {
            Label {
                text: qsTr('id_scan_to_send_here')
                Layout.fillWidth: true
            }
            ToolButton {
                icon.source: 'assets/svg/refresh.svg'
                icon.width: 16
                icon.height: 16
                onClicked: receive_address.generate()
            }
        }
        background: MouseArea {
            onClicked: copyAddress()
        }
        padding: 20
        Layout.fillWidth: true
        QRCode {
            id: qrcode
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: receive_address.generating ? 0 : 1.0
            text: url(address, amount)
            Behavior on opacity {
                OpacityAnimator { duration: 200 }
            }
            Rectangle {
                anchors.centerIn: parent
                border.width: 1
                border.color: '#00B45E'
                color: '#1000B45E'
                width: parent.height + 20
                height: width
                z: -1
            }
        }
    }

    Page {
        header: Label {
            text: qsTr('id_address')
        }
        background: MouseArea {
            onClicked: copyAddress()
        }
        Layout.fillWidth: true
        RowLayout {
            anchors.fill: parent
            Label {
                id: address_field
                text: receive_address.address
                horizontalAlignment: Label.AlignHCenter
                verticalAlignment: Label.AlignVCenter
                Layout.fillWidth: true
            }
            ToolButton {
                icon.source: 'assets/svg/copy_to_clipboard.svg'
                icon.width: 16
                icon.height: 16
                onClicked: copyAddress()
            }
        }
    }

    Page {
        header: Label {
            text: qsTr('id_add_amount_optional')
        }
        background: Item {}
        Layout.fillWidth: true
        RowLayout {
            anchors.fill: parent
            TextField {
                id: amount_field
                Layout.fillWidth: true
            }
            Button {
                flat: true
                text: 'BTC'
            }
        }
    }
}
