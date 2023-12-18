import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

WalletDrawer {
    required property Account account
    property Asset asset

    id: self
    minimumContentWidth: 400
    contentItem: GStackView {
        id: stack_view
        initialItem: SendPage {
            rightItem: CloseButton {
                onClicked: self.close()
            }
            context: self.context
            account: self.account
            asset: self.asset
        }
    }
}
