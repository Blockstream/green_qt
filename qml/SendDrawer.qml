import Blockstream.Green
import Blockstream.Green.Core
import QtQuick

import "analytics.js" as AnalyticsJS

WalletDrawer {
    property Asset asset
    property url url
    id: self
    minimumContentWidth: 450
    contentItem: GStackView {
        id: stack_view
        title: qsTrId('id_send')
        initialItem: RecipientPage {
            context: self.context
            account: null
            asset: null
            url: self.url
            onCloseClicked: self.close()
        }
    }
    AnalyticsView {
        name: 'Send'
        active: true
        segmentation: AnalyticsJS.segmentationSession(Settings, self.context)
    }
    onClosed: {
        if (self.url && stack_view.currentItem instanceof RecipientPage) {
            WalletManager.openUrl = self.url
        }
    }
}
