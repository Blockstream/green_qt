import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

import "analytics.js" as AnalyticsJS

ColumnLayout {
    property alias account: receive_address.account

    id: self
    spacing: 12

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

    Loader {
        Layout.alignment: Qt.AlignCenter
        active: account && account.wallet.network.liquid && account.wallet.device && account.wallet.device.type === Device.LedgerNanoS
        sourceComponent: GButton {
            icon.source: 'qrc:/svg/warning.svg'
            baseColor: '#e5e7e9'
            textColor: 'black'
            highlighted: true
            large: true
            text: qsTrId('id_ledger_supports_a_limited_set')
            onClicked: Qt.openUrlExternally('https://docs.blockstream.com/green/hww/hww-index.html#ledger-supported-assets')
            scale: hovered ? 1.01 : 1
            transformOrigin: Item.Center
            Behavior on scale {
                NumberAnimation {
                    easing.type: Easing.OutBack
                    duration: 400
                }
            }
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
            radius: 4
            color: '#1000B45E'
            width: parent.height + 16
            height: width
            z: -1
        }
    }

    SectionLabel {
        text: qsTrId('id_address')
    }

    CopyableLabel {
        delay: 200
        enabled: !receive_address.generating
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        Layout.rightMargin: constants.s2
        text: receive_address.uri
        wrapMode: Text.WrapAnywhere
        onCopy: {
            const account = receive_address.account
            const type = receive_address.uri.indexOf(':') > 0 ? 'uri' : 'address'
            Analytics.recordEvent('receive_address', AnalyticsJS.segmentationReceiveAddress(account, type))
        }
    }

    Loader {
        Layout.alignment: Qt.AlignCenter
        Layout.fillWidth: true
        active: account.wallet.device instanceof JadeDevice
        sourceComponent: ColumnLayout {
            spacing: 16
            SectionLabel {
                text: qsTrId('Verify receive address on Jade')
            }
            RowLayout {
                spacing: 16
                DeviceImage {
                    device: account.wallet.device
                    Layout.maximumHeight: 32
                    Layout.maximumWidth: paintedWidth
                }
                BusyIndicator {
                    Layout.leftMargin: -constants.s2
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
                HSpacer {
                }
                GButton {
                    large: true
                    text: {
                        if (receive_address.addressVerification === ReceiveAddressController.VerificationPending) return qsTrId('id_verify_on_device')
                        return qsTrId('Verify')
                    }
                    enabled: !receive_address.generating && receive_address.addressVerification !== ReceiveAddressController.VerificationPending
                    onClicked: {
                        Analytics.recordEvent('verify_address', AnalyticsJS.segmentationSubAccount(self.account))
                        receive_address.verify()
                    }
                }
            }
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
                text: wallet.displayUnit + ' ≈ ' + formatFiat(parseAmount(amount_field.text))
            }
        }
    }
}
