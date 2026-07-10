import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    required property Context context
    required property LightningSendController controller

    readonly property Asset asset: self.context.getOrCreateAsset('lnbtc')
    readonly property var amountSatoshi: self.controller.invoiceAmount ?? Number(self.controller.enteredSatoshi)

    id: self
    title: qsTrId('id_confirm_transaction')
    leftItem: BackButton {
        enabled: !self.controller.busy
        onClicked: self.popPage()
    }
    rightItem: CloseButton {
        enabled: !self.controller.busy
        onClicked: self.closeClicked()
    }
    footerItem: PrimaryButton {
        Layout.fillWidth: true
        busy: self.controller.busy
        enabled: self.controller.canPay
        text: qsTrId('id_send')
        onClicked: self.controller.pay()
    }

    Connections {
        target: self.controller
        function onPaid() {
            Settings.registerEvent({ invoice: self.controller.input })
            self.pushPage(transaction_completed_page)
        }
        function onFailed(error) {
            self.pushPage(transaction_failed_page, { error })
        }
    }

    Convert {
        id: amount_convert
        asset: self.asset
        context: self.context
        input: ({ satoshi: String(self.amountSatoshi ?? 0) })
        unit: self.context.primarySession.unit
    }
    Convert {
        id: success_amount_convert
        asset: self.asset
        context: self.context
        input: ({ satoshi: String(self.amountSatoshi ?? 0) })
        unit: self.context.primarySession.unit
    }

    contentItem: VFlickable {
        alignment: Qt.AlignTop
        spacing: 5
        FieldTitle {
            Layout.topMargin: 0
            text: qsTrId('id_asset')
        }
        Pane {
            Layout.fillWidth: true
            padding: 20
            background: Rectangle {
                border.color: '#262626'
                border.width: 1
                color: '#181818'
                radius: 5
            }
            contentItem: RowLayout {
                spacing: 12
                AssetIcon {
                    asset: self.asset
                    size: 32
                }
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    color: '#FFFFFF'
                    font.pixelSize: 16
                    font.weight: 600
                    text: self.asset.name
                    elide: Label.ElideRight
                }
            }
        }
        FieldTitle {
            text: qsTrId('id_recipient')
        }
        AddressLabel {
            Layout.fillWidth: true
            address: self.controller.invoice
            accentColor: '#DFB316'
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
            readOnly: true
            session: self.context.primarySession
            convert: amount_convert
        }
        ErrorPane {
            error: self.controller.error
        }
        VSpacer {
        }
    }

    Component {
        id: transaction_completed_page
        TransactionCompletedPage {
            message: qsTr('You transferred %1').arg(success_amount_convert.output.label)
            onCloseClicked: self.closeClicked()
        }
    }
    Component {
        id: transaction_failed_page
        TransactionFailedPage {
            onCloseClicked: self.closeClicked()
        }
    }
}
