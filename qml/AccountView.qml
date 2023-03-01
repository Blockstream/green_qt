import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import "util.js" as UtilJS

ColumnLayout {
    required property Account account

    id: account_view
    spacing: constants.p3

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
        currentIndex: UtilJS.findChildIndex(stack_layout, child => child.load)
        PersistentLoader {
            load: navigation.param.view === 'overview'
            sourceComponent: OverviewView {
                showAllAssets: false
                account: account_view.account
            }
        }

        PersistentLoader {
            load: navigation.param.view === 'assets'
            sourceComponent: AssetListView {
                account: account_view.account
            }
        }

        PersistentLoader {
            load: navigation.param.view === 'transactions'
            sourceComponent: TransactionListView {
                account: account_view.account
            }
        }

        PersistentLoader {
            load: navigation.param.view === 'addresses'
            sourceComponent: AddressesListView {
                account: account_view.account
            }
        }

        PersistentLoader {
            load: !account_view.account.wallet.watchOnly && navigation.param.view === 'coins'
            sourceComponent: OutputsListView {
                account: account_view.account
            }
        }
    }
}
