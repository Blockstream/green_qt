import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Layouts

StackViewPage {
    signal continueClicked(var properties)
    required property Context context
    required property Account account
    required property Asset asset
    required property string input
    required property var recipient
    property int items: 1
    readonly property string satoshi: amount_field.convert.result.satoshi ?? ''
    readonly property var error: {
        const send_amount = Number(controller.quote?.send_amount ?? 0)
        if (amount_field.text.length === 0) {
            return null
        }
        let value = Number(controller.quote?.min ?? 0)
        if (send_amount < value) {
            return { code: 'id_amount_below_minimum_allowed', value }
        }
        value = Number(controller.quote?.max ?? 0)
        if (send_amount > value) {
            return { code: 'id_amount_above_maximum_allowed', value }
        }
        value = self.account.json.satoshi[self.asset?.key] ?? 0
        if (send_amount > value) {
            return { code: 'id_insufficient_funds', value }
        }
        return null
    }
    onSatoshiChanged: {
        controller.send(self.satoshi)
    }
    RecipientParser {
        id: parser
        input: self.recipient.input
        data: {
            if (self.recipient.bolt12.amount) {
                return { items: self.items }
            } else {
                return { satoshi: self.satoshi }
            }
        }
    }
    SwapQuoteController {
        id: controller
        context: self.context
        sendNetworkKey: 'liquid'
        receiveNetworkKey: 'lightning'
    }
    id: self
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    title: 'BOLT12'
    footerItem: PrimaryButton {
        busy: parser.busy
        enabled: !parser.busy && self.error === null && (Number(amount_field.convert.result?.satoshi ?? 0) > 0 || (self.recipient?.bolt12?.amount ?? false))
        text: qsTrId('id_next')
        onClicked: {
            self.continueClicked({
                account: self.account,
                asset: self.asset,
                fiat: amount_field.fiat,
                input: self.input,
                recipient: parser.recipient,
                unit: amount_field.unit
            })
        }
    }
    contentItem: VFlickable {
        alignment: Qt.AlignTop
        spacing: 5
        AlertView {
            Layout.bottomMargin: 15
            alert: AnalyticsAlert {
                screen: 'Send'
                network: self.account.network.id
            }
        }
        FieldTitle {
            Layout.topMargin: 0
            text: qsTrId('id_account__asset')
        }
        AccountAssetField {
            Layout.fillWidth: true
            id: account_asset_field
            account: self.account
            asset: self.asset
            readonly: true
        }
        FieldTitle {
            text: qsTrId('id_amount')
        }
        AmountField {
            Layout.fillWidth: true
            id: amount_field
            error: self.error
            focus: true
            session: self.account.session
            readOnly: parser.recipient?.bolt12?.amount ?? false
            convert: Convert {
                asset: self.asset
                context: self.context
                input: ({ satoshi: Number(parser.recipient?.bolt12?.amount ?? '0') * self.items })
                unit: self.context.primarySession.unit
            }
        }
        Convert {
            id: error_value_convert
            asset: self.asset
            context: self.context
            input: ({ satoshi: String(self.error?.value ?? 0) })
            unit: amount_field.convert.unit
        }
        ErrorPane {
            Layout.topMargin: -15
            error: self.error ? qsTrId(self.error?.code) + ' - ' + (amount_field.fiat ? '~ ' + error_value_convert.fiat.label : error_value_convert.output.label) : null
        }
        VSpacer {
        }
        // Label {
        //     Layout.fillWidth: true
        //     Layout.preferredWidth: 0
        //     text: JSON.stringify(parser.recipient, null, 4)
        //     font.pixelSize: 10
        //     wrapMode: Label.WrapAtWordBoundaryOrAnywhere
        // }
    }
}
