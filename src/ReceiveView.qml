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

    spacing: 8

    ReceiveAddress {
        id: receive_address

        Binding on account {
            value: account
        }
    }

    Label {
        text: qsTr('id_scan_to_send_here')
        Layout.alignment: Qt.AlignHCenter
    }

    Item {
        Layout.minimumHeight: 128
        Layout.maximumHeight: 128
        Layout.minimumWidth: 384
        Layout.fillWidth: true
        Layout.fillHeight: true

        QRCode {
            id: qrcode
            anchors.fill: parent
            text: url(address, amount)
            opacity: receive_address.generating ? 0 : 1.0

            Behavior on opacity {
                OpacityAnimator { duration: 200 }
            }

            MouseArea {
                enabled: !receive_address.generating
                anchors.fill: parent
                onClicked: receive_address.copyToClipboard()
            }

            Rectangle {
                border.width: 1
                border.color: 'green'
                color: 'transparent'
                anchors.centerIn: parent
                width: parent.height + 8
                height: width
            }

        }

        BusyIndicator {
            anchors.centerIn: parent
            visible: receive_address.generating
        }
    }

    Page {
        header: Label {
            text: qsTr('id_address')
        }
        background: MouseArea {
            onClicked: {
                receive_address.copyToClipboard()
                ToolTip.show(qsTr('id_address_copied_to_clipboard'), 1000)
            }
        }
        Layout.fillWidth: true
        RowLayout {
            TextField {
                id: address_field
                Layout.fillWidth: true
                text: address
                readOnly: true
                horizontalAlignment: Label.AlignHCenter
                verticalAlignment: Label.AlignVCenter
            }
            Image {
                source: 'assets/svg/copy_to_clipboard.svg'
            }
        }
    }

    Label {
        text: qsTr('id_add_amount_optional')
    }

    RowLayout {
        TextField {
            id: amount_field
            Layout.fillWidth: true
        }

        Button {
            text: 'BTC'
        }
    }
}
