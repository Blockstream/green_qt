import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS

WalletDialog {
    required property Account account

    id: self
    wallet: self.account.wallet
    title: qsTrId('id_receive')
    icon: 'qrc:/svg/receive.svg'
    onClosed: destroy()
    contentItem: ReceiveView {
        account: self.account
    }
    footer: DialogFooter {
    }
    AnalyticsView {
        name: 'Receive'
        active: self.opened
        segmentation: AnalyticsJS.segmentationSubAccount(self.account)
    }
}
