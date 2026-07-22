import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    required property Context context
    required property Account account
    required property Asset asset
    required property string address
    required property string amount
    required property string fee
    required property string pset

    id: self
    title: qsTrId('id_confirm_transaction')
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }

    Amp2SignController {
        id: controller
        context: self.context
        account: self.account
        pset: self.pset
        onCompleted: (txhash) => {
            // The lookup can miss if the post-broadcast refresh scan failed
            // (transient Waterfalls error); pass the txhash explicitly so the
            // completed page still shows the txid either way.
            self.pushPage(transaction_completed_page, {
                transaction: self.account.getTransactionByTxHash(txhash),
                txhash,
            })
        }
        onFailed: (error) => {
            self.pushPage(transaction_failed_page, { error })
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
            address: self.address
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
            session: self.account.session
            readOnly: true
            convert: Convert {
                asset: self.asset
                context: self.context
                unit: self.account.session.unit
                input: ({ satoshi: self.amount })
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
            input: ({ satoshi: self.fee })
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
            enabled: !controller.busy
            busy: controller.busy
            text: qsTrId('id_confirm_transaction')
            onClicked: controller.sign()
        }
    }

    Component {
        id: transaction_failed_page
        TransactionFailedPage {
            onCloseClicked: self.closeClicked()
        }
    }

    Component {
        id: transaction_completed_page
        TransactionCompletedPage {
            onCloseClicked: self.closeClicked()
        }
    }
}
