import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

Page {
    required property Context context
    required property Account account

    id: self
    spacing: constants.s1
    background: null

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

    TransactionListModel {
        id: transaction_list_model
        account: self.account
    }

    AddressListModel {
        id: address_model
        account: self.account
    }

    OutputListModel {
        id: output_model
        account: self.account
        onModelAboutToBeReset: selection_model.clear()
    }

    // TODO rename
    ButtonGroup {
        id: button_group
    }

    OutputListModelFilter {
        id: output_model_filter
        filter: button_group.checkedButton?.buttonTag ?? ''
        model: output_model
    }

    ItemSelectionModel {
        id: selection_model
        model: output_model
    }

    Component {
        id: transaction_dialog
        TransactionView {
        }
    }

    Component {
        id: balance_dialog
        AssetView {
        }
    }

    contentItem: StackLayout {
        id: stack_layout


        currentIndex: UtilJS.findChildIndex(stack_layout, child => child.load)

        PersistentLoader {
            load: navigation.param.view === 'transactions'
            sourceComponent: TransactionListView {
                account: self.account
                leftPadding: 0
            }
        }

        PersistentLoader {
            load: navigation.param.view === 'addresses'
            sourceComponent: AddressesListView {
                account: self.account
                leftPadding: 0
            }
        }

        PersistentLoader {
            load: !(self.account?.context?.watchonly ?? false) && navigation.param.view === 'coins'
            sourceComponent: OutputsListView {
                account: self.account
            }
        }
    }

    PersistentLoader {
        load: navigation.param.view === 'assets'
        sourceComponent: AssetListView {
            account: self.account
        }
    }
}
