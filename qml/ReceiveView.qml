import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

ColumnLayout {
    property alias account: receive_address.account
    spacing: 16

    ReceiveAddressController {
        id: receive_address
        amount: amount_field.text
    }

    Action {
        id: refresh_action
        icon.source: 'qrc:/svg/refresh.svg'
        icon.width: 16
        icon.height: 16
        enabled: !receive_address.generating && receive_address.addressVerification !== ReceiveAddressController.VerificationPending
        onTriggered: receive_address.generate()
    }

    Action {
        id: copy_address_action
        onTriggered: {
            if (receive_address.generating) return;
            Clipboard.copy(receive_address.uri)
            qrcode.ToolTip.show(qsTrId('id_copied_to_clipboard'), 1000);
        }
    }

    RowLayout {
        SectionLabel {
            text: qsTrId('id_scan_to_send_here')
            Layout.fillWidth: true
        }
        ToolButton {
            action: refresh_action
            ToolTip.text: qsTrId('id_generate_new_address')
            ToolTip.delay: 300
            ToolTip.visible: hovered
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
            text: receive_address.uri
            horizontalAlignment: Label.AlignHCenter
            verticalAlignment: Label.AlignVCenter
            Layout.fillWidth: true
            Layout.minimumWidth: 400
            Layout.maximumWidth: 400
            wrapMode: Text.WrapAnywhere
        }
        ToolButton {
            enabled: !receive_address.generating && (receive_address.addressVerification === ReceiveAddressController.VerificationNone || receive_address.addressVerification === ReceiveAddressController.VerificationAccepted)
            icon.source: 'qrc:/svg/copy.svg'
            icon.width: 16
            icon.height: 16
            action: copy_address_action
            ToolTip.text: qsTrId('id_copy_to_clipboard')
            ToolTip.delay: 300
            ToolTip.visible: hovered
        }
    }
    Loader {
        Layout.alignment: Qt.AlignCenter
        Layout.fillWidth: true
        active: account.wallet.device instanceof JadeDevice
        sourceComponent: ColumnLayout {
            spacing: 16
            SectionLabel {
                text: qsTrId('Verify address matches the one displayed on Jade')
            }
            RowLayout {
                spacing: 16
                DeviceImage {
                    device: account.wallet.device
                    Layout.maximumHeight: 32
                    Layout.maximumWidth: paintedWidth
                }
                GButton {
                    large: true
                    text: {
                        if (receive_address.addressVerification === ReceiveAddressController.VerificationNone) return qsTrId('Verify')
                        if (receive_address.addressVerification === ReceiveAddressController.VerificationPending) return qsTrId('Check Jade')
                        return qsTrId('Verify again')
                    }
                    enabled: !receive_address.generating && receive_address.addressVerification !== ReceiveAddressController.VerificationPending
                    onClicked: receive_address.verify()
                }
                HSpacer {
                }
                BusyIndicator {
                    Layout.maximumHeight: 32
                    running: receive_address.addressVerification === ReceiveAddressController.VerificationPending
                    visible: running
                }
                Image {
                    visible: receive_address.addressVerification === ReceiveAddressController.VerificationAccepted
                    Layout.maximumWidth: 24
                    Layout.maximumHeight: 24
                    source: 'qrc:/svg/check.svg'
                }
                Image {
                    visible: receive_address.addressVerification === ReceiveAddressController.VerificationRejected
                    Layout.maximumWidth: 16
                    Layout.maximumHeight: 16
                    source: 'qrc:/svg/x.svg'
                }
            }

//            font.capitalization: Font.AllUppercase
//            font.styleName: 'Medium'
//            padding: 8
//            background: Rectangle {
//                radius: 4
//                color: '#b74747'
//            }
        }
    }
    SectionLabel {
        text: qsTrId('id_add_amount_optional')
    }
    RowLayout {
        GTextField {
            id: amount_field
            horizontalAlignment: TextField.AlignRight
            rightPadding: unit.width + 16
            Layout.fillWidth: true
            validator: AmountValidator {
            }
            Label {
                id: unit
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.baseline: parent.baseline
                text: (wallet.network.liquid ? 'L-'+wallet.settings.unit : wallet.settings.unit) +
                      ' ≈ ' + formatFiat(parseAmount(amount_field.text))
            }
        }
    }
}
