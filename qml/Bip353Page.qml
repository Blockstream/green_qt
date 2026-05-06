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
    RecipientParser {
        id: parser
        input: self.recipient.input
        data: ({ satoshi: amount_field.convert.result.satoshi ?? '' })
    }
    id: self
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    title: 'BIP353'
    footerItem: PrimaryButton {
        id: confirm_button
        busy: parser.busy
        enabled: !parser.busy && Number(amount_field.convert.result.satoshi) > 0
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
        Bip353AddressField {
            address: self.recipient.bip353
        }
        FieldTitle {
            text: qsTrId('id_amount')
        }
        AmountField {
            Layout.fillWidth: true
            id: amount_field
            session: self.account.session
            convert: Convert {
                asset: self.asset
                context: self.context
                unit: self.context.primarySession.unit
            }
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

    component Bip353AddressField: Label {
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
