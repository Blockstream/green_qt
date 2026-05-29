import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

StackViewPage {
    signal continueClicked(var properties)
    required property Context context
    required property Account account
    required property Asset asset
    required property string input
    required property var recipient
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
        data: ({ satoshi: self.satoshi })
    }
    SwapQuoteController {
        id: controller
        context: self.context
        lightning: true
        sendNetworkKey: 'liquid'
        receiveNetworkKey: 'bitcoin'
    }
    id: self
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    title: 'Pay Lightning Address'
    footerItem: PrimaryButton {
        id: confirm_button
        enabled: !parser.busy && self.error === null && (parser.recipient?.invoice ?? false)
        busy: parser.busy
        text: qsTrId('id_confirm')
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
            text: qsTrId('id_address')
        }
        LightningAddressField {
            address: self.recipient.lnurl.address
        }
        FieldTitle {
            text: qsTrId('id_amount')
        }
        AmountField {
            Layout.fillWidth: true
            id: amount_field
            error: self.error
            session: self.account.session
            convert: Convert {
                asset: self.asset
                context: self.context
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

    component LightningAddressField: Label {
        required property string address
        Layout.fillWidth: true
        id: field
        font.pixelSize: 16
        font.weight: 400
        horizontalAlignment: Text.AlignHCenter
        elide: Label.ElideMiddle
        text: field.address
        wrapMode: Label.WordWrap
        padding: 20
        background: Rectangle {
            color: '#181818'
            radius: 5
        }
    }
}
