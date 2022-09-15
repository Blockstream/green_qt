import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

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

    AnalyticsView {
        name: 'Receive'
        active: self.opened
        segmentation: segmentationSubAccount(self.account)
    }
}
