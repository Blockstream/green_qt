import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

ColumnLayout {
    spacing: 16

    ReceiveAddress {
        id: receive_address
        amount: amount_field.text

        Binding on account {
            value: account
        }
    }

    Action {
        id: refresh_action
        icon.source: '/svg/refresh.svg'
        icon.width: 16
        icon.height: 16
        onTriggered: receive_address.generate()
    }

    Action {
        id: copy_address_action
        text: qsTrId('id_copy_address')
        onTriggered: {
            if (receive_address.generating) return;
            receive_address.copyToClipboard();
            qrcode.ToolTip.show(qsTr('id_address_copied_to_clipboard'), 1000);
        }
    }

    Action {
        id: copy_uri_action
        enabled: !wallet.network.liquid
        text: qsTrId('id_copy_uri')
        onTriggered: {
            if (receive_address.generating) return;
            receive_address.copyUriToClipboard();
            qrcode.ToolTip.show(qsTr('id_copied_to_clipboard'), 1000);
        }
    }

    RowLayout {
        SectionLabel {
            text: qsTrId('id_scan_to_send_here')
            Layout.fillWidth: true
        }
        ToolButton {
            action: refresh_action
        }
    }

    QRCode {
        id: qrcode
        opacity: receive_address.generating ? 0 : 1.0
        text: receive_address.uri
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
            text: receive_address.address
            horizontalAlignment: Label.AlignHCenter
            verticalAlignment: Label.AlignVCenter
            Layout.fillWidth: true
            Layout.minimumWidth: 400
        }
        ToolButton {
            enabled: !receive_address.generating
            icon.source: '/svg/copy_to_clipboard.svg'
            icon.width: 16
            icon.height: 16
            onClicked: copy_menu.open()
            Menu {
                id: copy_menu
                MenuItem {
                    action: copy_address_action
                }
                MenuItem {
                    action: copy_uri_action
                }
            }
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
