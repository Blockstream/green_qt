import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS

ControllerDialog {
    required property Account account

    controller: ReceiveAddressController {
        id: controller
        account: self.account
        context: self.account.context
        amount: amount_field.text
    }

    id: self
    wallet: self.account.context.wallet
    title: qsTrId('id_receive')
    icon: 'qrc:/svg/receive.svg'

    AnalyticsView {
        name: 'Receive'
        active: self.opened
        segmentation: AnalyticsJS.segmentationSubAccount(self.account)
    }
    Action {
        id: refresh_action
        icon.source: 'qrc:/svg/refresh.svg'
        icon.width: 16
        icon.height: 16
        enabled: !controller.generating && controller.addressVerification !== ReceiveAddressController.VerificationPending
        onTriggered: controller.generate()
    }

    ColumnLayout {
        spacing: constants.s1
        Loader {
            Layout.alignment: Qt.AlignCenter
            active: account?.network?.liquid && account.context.device?.type === Device.LedgerNanoS
            visible: active
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
            visible: false
            Layout.fillHeight: false
            SectionLabel {
                text: qsTrId('id_scan_to_send_here')
                Layout.fillWidth: true
            }
        }

        QRCode {
            id: qrcode
            opacity: controller.generating ? 0.2 : 1.0
            text: controller.uri
            Layout.alignment: Qt.AlignHCenter
            Behavior on opacity {
                OpacityAnimator { duration: 200 }
            }
        }

        SectionLabel {
            text: qsTrId('id_address')
        }

        RowLayout {
            enabled: !controller.generating
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.minimumWidth: 400
                Layout.minimumHeight: contentHeight
                wrapMode: Text.WrapAnywhere
                text: controller.uri
            }
            ToolButton {
                action: refresh_action
                ToolTip.text: qsTrId('id_generate_new_address')
                ToolTip.delay: 300
                ToolTip.visible: hovered
            }
            ToolButton {
                icon.source: 'qrc:/svg/copy.svg'
                onClicked: {
                    Clipboard.copy(controller.uri)
                    const account = controller.account
                    const type = controller.uri.indexOf(':') > 0 ? 'uri' : 'address'
                    Analytics.recordEvent('receive_address', AnalyticsJS.segmentationReceiveAddress(account, type))
                    ToolTip.show(qsTrId('id_copied_to_clipboard'), 1000)

                }
                ToolTip.text: qsTrId('id_copy_address')
                ToolTip.delay: 300
                ToolTip.visible: hovered
            }
        }

//        CopyableLabel {
//            delay: 200
//            enabled: !controller.generating
//            Layout.fillWidth: true
//            Layout.preferredWidth: 0
//            text: controller.uri
//            wrapMode: Text.WrapAnywhere
//            onCopy: {
//                const account = controller.account
//                const type = controller.uri.indexOf(':') > 0 ? 'uri' : 'address'
//                Analytics.recordEvent('receive_address', AnalyticsJS.segmentationReceiveAddress(account, type))
//            }
//        }

        Loader {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            active: account.context.device instanceof JadeDevice
            visible: active
            sourceComponent: ColumnLayout {
                spacing: 16
                SectionLabel {
                    text: qsTrId('Verify receive address on Jade')
                }
                RowLayout {
                    spacing: 16
                    DeviceImage {
                        device: account.context.device
                        Layout.maximumHeight: 32
                        Layout.maximumWidth: paintedWidth
                    }
                    BusyIndicator {
                        Layout.leftMargin: -constants.s2
                        Layout.maximumHeight: 32
                        running: controller.addressVerification === ReceiveAddressController.VerificationPending
                        visible: running
                    }
                    Image {
                        visible: controller.addressVerification === ReceiveAddressController.VerificationAccepted
                        Layout.maximumWidth: 24
                        Layout.maximumHeight: 24
                        source: 'qrc:/svg/check.svg'
                    }
                    Image {
                        visible: controller.addressVerification === ReceiveAddressController.VerificationRejected
                        Layout.maximumWidth: 16
                        Layout.maximumHeight: 16
                        source: 'qrc:/svg/x.svg'
                    }
                    HSpacer {
                    }
                    GButton {
                        large: true
                        text: {
                            if (controller.addressVerification === ReceiveAddressController.VerificationPending) return qsTrId('id_verify_on_device')
                            return qsTrId('Verify')
                        }
                        enabled: !controller.generating && controller.addressVerification !== ReceiveAddressController.VerificationPending
                        onClicked: {
                            Analytics.recordEvent('verify_address', AnalyticsJS.segmentationSubAccount(self.account))
                            controller.verify()
                        }
                    }
                }
            }
        }

        SectionLabel {
            text: qsTrId('id_add_amount_optional')
        }

        RowLayout {
            Layout.fillHeight: false
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
                    text: wallet.context.displayUnit + ' ≈ ' + formatFiat(parseAmount(amount_field.text))
                }
            }
        }
    }
}
