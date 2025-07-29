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
    property url url
    id: self
    closePolicy: AbstractDrawer.CloseOnEscape
    minimumContentWidth: 450
    contentItem: GStackView {
        id: stack_view
        initialItem: SendPage {
            context: self.context
            account: self.account
            asset: self.asset
            url: self.url
            onClosed: self.close()
        }
    }
    AnalyticsView {
        name: 'Send'
        active: true
        segmentation: AnalyticsJS.segmentationSubAccount(Settings, self.account)
    }
    onClosed: {
        if (self.url && stack_view.currentItem instanceof SendPage) {
            WalletManager.openUrl = self.url
        }
    }
}
