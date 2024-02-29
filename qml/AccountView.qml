import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

Page {
    signal transactionClicked(Transaction transaction)
    signal addressClicked(Address address)
    signal assetClicked(Account account, Asset asset)
    required property Context context
    required property Account account

    id: self
    spacing: constants.s1
    background: null

    AnalyticsView {
        name: 'Overview'
        active: UtilJS.effectiveVisible(self)
        segmentation: AnalyticsJS.segmentationSubAccount(Settings, self.account)
    }

    TransactionListModel {
        id: transaction_list_model
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

    contentItem: StackLayout {
        id: stack_layout


        currentIndex: UtilJS.findChildIndex(stack_layout, child => child.load)

        PersistentLoader {
            load: navigation.param.view === 'transactions'
            sourceComponent: TransactionListView {
                account: self.account
                leftPadding: 0
                onTransactionClicked: (transaction) => self.transactionClicked(transaction)
            }
        }

        PersistentLoader {
            load: navigation.param.view === 'addresses'
            sourceComponent: AddressesListView {
                account: self.account
                leftPadding: 0
                onAddressClicked: (address) => self.addressClicked(address)
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
            context: self.context
            account: self.account
            onAssetClicked: (asset) => self.assetClicked(self.account, asset)
        }
    }
}
