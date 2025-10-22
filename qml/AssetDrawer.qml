import Blockstream.Green
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

WalletDrawer {
    signal accountClicked(Asset asset, Account account)
    signal transactionsClicked(Asset asset)
    required property Asset asset
    id: self
    contentItem: AssetDetailsPage {
        context: self.context
        asset: self.asset
        closeAction: Action {
            onTriggered: self.close()
        }
        onAccountClicked: (account) => {
            self.close()
            self.accountClicked(self.asset, account)
        }
        onTransactionsClicked: {
            self.close()
            self.transactionsClicked(self.asset)
        }
    }
}
