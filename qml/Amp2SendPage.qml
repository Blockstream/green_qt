import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    required property Context context
    required property Account account
    required property Asset asset
    required property string input
    required property var recipient
    readonly property var available: ({ satoshi: String(self.account.json.satoshi[self.asset?.key ?? 'btc'] ?? 0) })

    id: self
    title: qsTrId('id_details')
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }

    CreatePsetController {
        id: controller
        context: self.context
        account: self.account
        asset: self.asset
        recipient.convert.unit: self.account.session.unit
        recipient.address: self.recipient?.address?.address ?? ''
    }

    contentItem: VFlickable {
        alignment: Qt.AlignTop
        spacing: 5
        FieldTitle {
            Layout.topMargin: 0
            text: qsTrId('id_account__asset')
        }
        AccountAssetField {
            Layout.fillWidth: true
            account: self.account
            asset: self.asset
            readonly: true
        }
        FieldTitle {
            text: qsTrId('id_address')
        }
        AddressLabel {
            Layout.fillWidth: true
            address: controller.recipient.address
            padding: 20
            background: Rectangle {
                color: '#181818'
                radius: 5
            }
        }
        FieldTitle {
            text: qsTrId('id_amount')
        }
        AmountField {
            Layout.fillWidth: true
            id: amount_field
            error: {
                if (amount_field.text.length === 0 && !controller.recipient.greedy) return
                if (controller.error.includes('InsufficientFunds')) {
                    return 'id_insufficient_funds'
                }
                return null
            }
            focus: true
            session: self.account.session
            convert: controller.recipient.convert
            onCleared: controller.recipient.greedy = false
            onTextEdited: controller.recipient.greedy = false
        }
        ErrorPane {
            Layout.topMargin: -15
            Layout.bottomMargin: 15
            error: amount_field.text.length > 0 || controller.recipient.greedy ? amount_field.error : null
        }
        Convert {
            id: available_convert
            account: self.account
            asset: self.asset
            input: self.available
            unit: controller.recipient.convert.unit
        }
        RowLayout {
            spacing: 10
            Label {
                Layout.fillWidth: true
                font.features: { 'calt': 0, 'zero': 1 }
                font.pixelSize: 14
                font.weight: 500
                opacity: 0.4
                text: qsTrId('id_available') + ' ' + (amount_field.fiat ? '~ ' + available_convert.fiat.label : available_convert.output.label)
                visible: !amount_field.fiat || available_convert.fiat.available
            }
            LinkButton {
                Layout.alignment: Qt.AlignTop
                enabled: !controller.recipient.greedy
                font.pixelSize: 14
                font.weight: 600
                text: qsTrId('id_send_all')
                visible: self.asset?.id === self.account.network.policyAsset
                onClicked: controller.recipient.greedy = true
            }
        }
        ErrorPane {
            error: {
                if (controller.error.includes('InsufficientFunds')) {
                    return
                }
                return controller.error
            }
        }
        VSpacer {
        }
    }

    footerItem: ColumnLayout {
        spacing: 5
        Convert {
            id: fee_convert
            account: self.account
            input: ({ satoshi: String(controller.transaction.fee ?? 0) })
            unit: self.account.session.unit
        }
        Item {
            Layout.minimumHeight: 5
        }
        RowLayout {
            Label {
                font.pixelSize: 14
                font.weight: 500
                text: qsTrId('id_network_fee')
            }
            HSpacer {
            }
            Label {
                font.features: { 'calt': 0, 'zero': 1 }
                font.pixelSize: 14
                font.weight: 500
                text: fee_convert.output.label
            }
        }
        RowLayout {
            Layout.bottomMargin: 20
            HSpacer {
            }
            Label {
                font.features: { 'calt': 0, 'zero': 1 }
                color: '#6F6F6F'
                font.pixelSize: 12
                font.weight: 400
                text: '~ ' + fee_convert.fiat.label
            }
        }
        PrimaryButton {
            Layout.alignment: Qt.AlignCenter
            Layout.minimumWidth: 200
            enabled: !controller.busy && controller.pset.length > 0 && controller.error.length === 0
            busy: controller.busy
            text: qsTrId('id_next')
            onClicked: {
                self.pushPage(sign_page, {
                    account: self.account,
                    asset: self.asset,
                    address: controller.recipient.address,
                    amount: String(controller.transaction.satoshi),
                    fee: String(controller.transaction.fee),
                    pset: controller.pset,
                })
            }
        }
    }

    Component {
        id: sign_page
        Amp2SignPage {
            context: self.context
            onCloseClicked: self.closeClicked()
        }
    }
}
