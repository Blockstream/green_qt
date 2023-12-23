import Blockstream.Green
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

WalletDrawer {
    signal accountClicked(Account account)
    required property Asset asset
    property Account account
    id: self
    contentItem: AssetDetailsPage {
        context: self.context
        asset: self.asset
        account: self.account
        closeAction: Action {
            onTriggered: self.close()
        }
        onAccountClicked: (account) => {
            self.close()
            self.accountClicked(account)
        }
    }
}
