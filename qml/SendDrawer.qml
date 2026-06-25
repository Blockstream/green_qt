import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls

import "analytics.js" as AnalyticsJS

WalletDrawer {
    property Asset asset
    property url url
    property bool lightningOnly: false
    id: self
    closePolicy: recipient_page.closeBlocked ? Popup.NoAutoClose : Popup.CloseOnEscape | Popup.CloseOnPressOutside
    minimumContentWidth: 450
    contentItem: GStackView {
        id: stack_view
        title: qsTrId('id_send')
        initialItem: RecipientPage {
            id: recipient_page
            context: self.context
            account: null
            asset: null
            url: self.url
            lightningOnly: self.lightningOnly
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
