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
    property var currentView: account_view.account.wallet.network.liquid ? 0 : 2

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

    StackLayout {
        id: stack_layout
        Layout.fillWidth: true
        Layout.fillHeight: true
        currentIndex: account_view.currentView

        OverviewView {
            id: overview_view
            showAllAssets: false
            account: account_view.account
        }

        AssetListView {
            account: account_view.account
        }

        TransactionListView {
            account: account_view.account
        }

        Loader {
            active: !account_view.account.wallet.watchOnly
            sourceComponent: AddressesListView {
                id: addresses_view
                account: account_view.account
            }
        }

        Loader {
            active: !account_view.account.wallet.watchOnly
                sourceComponent: OutputsListView {
                id: outputs_view
                account: account_view.account
            }
        }
    }
}
