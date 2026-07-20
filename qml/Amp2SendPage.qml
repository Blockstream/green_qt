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

    id: self
    title: qsTrId('id_send')
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }

    CreatePsetController {
        id: controller
        context: self.context
        account: self.account
        address: self.recipient?.address?.address ?? ''
        assetId: self.asset?.id ?? ''
        amount: amount_field.convert.result.satoshi ?? ''
        onCreated: {
            self.pushPage(sign_page, {
                account: self.account,
                asset: self.asset,
                address: controller.address,
                amount: String(controller.transaction.satoshi),
                fee: String(controller.transaction.fee),
                pset: controller.pset,
            })
        }
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
            address: controller.address
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
            focus: true
            session: self.account.session
            convert: Convert {
                asset: self.asset
                context: self.context
                unit: self.account.session.unit
            }
        }
        ErrorPane {
            Layout.topMargin: 10
            error: controller.error
        }
        VSpacer {
        }
    }

    footerItem: PrimaryButton {
        Layout.alignment: Qt.AlignCenter
        Layout.minimumWidth: 200
        enabled: !controller.busy && amount_field.text.length > 0 && controller.address.length > 0
        busy: controller.busy
        text: qsTrId('id_next')
        onClicked: controller.create()
    }

    Component {
        id: sign_page
        Amp2SignPage {
            context: self.context
            onCloseClicked: self.closeClicked()
        }
    }
}
