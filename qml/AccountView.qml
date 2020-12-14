import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.14
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

StackView {
    id: account_view
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

    initialItem: Page {
        background: Item {}
        header: RowLayout {
            TabBar {
                id: tab_bar
                leftPadding: 16
                background: Item {}
                TabButton {
                    text: qsTrId('id_transactions')
                    width: 160
                }

                TabButton {
                    visible: account && account.wallet.network.liquid
                    text: qsTrId('id_assets')
                    width: 160
                }
            }
        }
        contentItem: StackLayout {
            id: stack_layout
            currentIndex: tab_bar.currentIndex
            TransactionListView {
                account: account_view.account
                onClicked: account_view.push(transaction_view_component, { transaction })
            }
            Loader {
                active: account && account.wallet.network.liquid
                sourceComponent: AssetListView {
                    account: account_view.account
                    onClicked: account_view.push(asset_view_component, { balance })
                }
            }
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
}
