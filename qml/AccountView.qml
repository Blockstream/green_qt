import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.14
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

ColumnLayout {
    id: account_view
    spacing: constants.p3
    required property Account account

    function getUnblindingData(tx) {
        return {
            version: 0,
            txid: tx.txhash,
            type: tx.type,
            inputs: tx.inputs
                .filter(i => i.asset_id && i.satoshi && i.assetblinder && i.amountblinder)
                .map(i => ({
                   vin: i.pt_idx,
                   asset_id: i.asset_id,
                   assetblinder: i.assetblinder,
                   satoshi: i.satoshi,
                   amountblinder: i.amountblinder,
                })),
            outputs: tx.outputs
                .filter(o => o.asset_id && o.satoshi && o.assetblinder && o.amountblinder)
                .map(o => ({
                   vout: o.pt_idx,
                   asset_id: o.asset_id,
                   assetblinder: o.assetblinder,
                   satoshi: o.satoshi,
                   amountblinder: o.amountblinder,
                })),
        }
    }

    function copyUnblindingData(item, tx) {
        Clipboard.copy(JSON.stringify(getUnblindingData(tx), null, '  '))
        item.ToolTip.show(qsTrId('id_copied_to_clipboard'), 2000);
    }

    RowLayout {
        id: toolbar
        Layout.fillWidth: true
        spacing: constants.p1
        TabButton {
            visible: account_view.account.wallet.network.liquid
            icon.source: "qrc:/svg/overview.svg"
            ToolTip.text: qsTrId('id_overview')
            checked: stack_layout.currentIndex === 0 && overview_view.active
            onClicked: navigation.go(`/${wallet.network.id}/${wallet.id}/overview`)
        }
        TabButton {
            visible: account_view.account.wallet.network.liquid
            icon.source: "qrc:/svg/assets.svg"
            ToolTip.text: qsTrId('id_assets')
            checked: assets_view.active || asset_view.active
            onClicked: navigation.go(`/${wallet.network.id}/${wallet.id}/assets`)
        }
        TabButton {
            checked: transactions_view.active || transaction_view.active
            icon.source: "qrc:/svg/transactions.svg"
            ToolTip.text: qsTrId('id_transactions')
            onClicked: navigation.go(`/${wallet.network.id}/${wallet.id}/transactions`)
        }
        TabButton {
            checked: addresses_view.active
            icon.source: "qrc:/svg/addresses.svg"
            ToolTip.text: qsTrId('id_addresses')
            onClicked: navigation.go(`/${wallet.network.id}/${wallet.id}/addresses`)
        }
        HSpacer {
        }
        GButton {
            id: send_button
            Layout.alignment: Qt.AlignRight
            large: true
            enabled: !wallet.locked && account.balance > 0
            hoverEnabled: true
            text: qsTrId('id_send')
            onClicked: send_dialog.createObject(window, { account: account_view.account }).open()
            ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
            ToolTip.text: qsTrId('id_insufficient_lbtc_to_send_a')
            ToolTip.visible: hovered && !enabled
        }
        GButton {
            Layout.alignment: Qt.AlignRight
            large: true
            enabled: !wallet.locked
            text: qsTrId('id_receive')
            onClicked: receive_dialog.createObject(window, { account: account_view.account }).open()
        }
    }

    StackLayout {
        id: stack_layout
        Layout.fillWidth: true
        Layout.fillHeight: true
        currentIndex: {
            let index = -1
            for (let i = 0; i < stack_layout.children.length; ++i) {
                let child = stack_layout.children[i]
                if (!(child instanceof Item)) continue
                if (child.active) index = i
            }
            return index
        }

        OverviewView {
            id: overview_view
            property bool active: account_view.account.wallet.network.liquid
            showAllAssets: false
        }

        AssetListView {
            id: assets_view
            property bool active: navigation.location.indexOf("assets")>0
            account: account_view.account
            onClicked: navigation.go(`/${wallet.network.id}/${wallet.id}/${account_view.account.json.pointer}/${balance.asset.id}`)
        }

        Loader {
            id: asset_view
            active: {
                const [,,wallet_id,pointer,asset_id] = navigation.location.split('/')
                if (account_view.account.wallet.id!==wallet_id) return false
                if (account_view.account.json.pointer!=pointer) return false // it is important that the comparision is made this way because the types differ
                if (account_view.account.getBalanceByAssetId(asset_id)===null) return false
                return true;
            }
            sourceComponent: AssetView {
                balance: {
                    const [,,,,asset_id] = navigation.location.split('/')
                    return account_view.account.getBalanceByAssetId(asset_id)
                }
            }
        }

        TransactionListView {
            id: transactions_view
            property bool active: navigation.location.indexOf("transactions")>0
            account: account_view.account
            onClicked: navigation.go(`/${wallet.network.id}/${wallet.id}/${account_view.account.json.pointer}/${transaction.data.txhash}`)
        }

        Loader {
            id: transaction_view
            active: {
                const [,,wallet_id,pointer,transaction_id] = navigation.location.split('/')
                if (account_view.account.wallet.id!==wallet_id) return false
                if (account_view.account.json.pointer!=pointer) return false // it is important that the comparision is made this way because the types differ
                if (account_view.account.getTransactionByTxHash(transaction_id)===null) return false
                return true;
            }
            sourceComponent: TransactionView {
                transaction: {
                    const [,,,,transaction_id] = navigation.location.split('/')
                    return account_view.account.getTransactionByTxHash(transaction_id)
                }
            }
        }

        AddressesListView {
            id: addresses_view
            property bool active: navigation.location.indexOf("addresses")>0
            account: account_view.account
        }
    }

    Component {
        id: transaction_view_component
        TransactionView { }
    }

    Component {
        id: asset_view_component
        AssetView { }
    }

    Component {
        id: send_dialog
        SendDialog { }
    }

    Component {
        id: receive_dialog
        ReceiveDialog { }
    }

    component TabButton: ToolButton {
        icon.width: constants.p4
        icon.height: constants.p4
        icon.color: 'white'
        padding: 4
        background: Rectangle {
            color: parent.checked ? constants.c400 : parent.hovered ? constants.c600 : constants.c700
            radius: 4
        }
        ToolTip.delay: 300
        ToolTip.visible: hovered
    }
}
