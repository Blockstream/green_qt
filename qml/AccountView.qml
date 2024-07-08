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
    required property string view

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

    contentItem: StackLayout {
        id: stack_layout


        currentIndex: UtilJS.findChildIndex(stack_layout, child => child.load)

        PersistentLoader {
            load: self.view === 'transactions'
            sourceComponent: TransactionListView {
                account: self.account
                leftPadding: 0
                onTransactionClicked: (transaction) => self.transactionClicked(transaction)
            }
        }

        PersistentLoader {
            load: self.view === 'addresses'
            sourceComponent: AddressesListView {
                account: self.account
                leftPadding: 0
                onAddressClicked: (address) => self.addressClicked(address)
            }
        }

        PersistentLoader {
            load: !(self.account?.context?.watchonly ?? false) && self.view === 'coins'
            sourceComponent: OutputsListView {
                account: self.account
            }
        }
    }

    PersistentLoader {
        load: self.view === 'assets'
        sourceComponent: AssetListView {
            context: self.context
            account: self.account
            onAssetClicked: (asset) => self.assetClicked(self.account, asset)
        }
    }
}
