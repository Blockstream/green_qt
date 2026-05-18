import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls

WalletDrawer {
    id: self
    preferredContentWidth: stack_view.currentItem.implicitWidth
    minimumContentWidth: 400
    contentItem: GStackView {
        id: stack_view
        title: qsTrId('id_receive')
        initialItem: ReceiveAccountAssetSelector {
            context: self.context
            onCloseClicked: self.close()
            onSelected: (account, asset) => {
                stack_view.replace(null, receive_page, { account, asset }, StackView.PushTransition)
            }
        }
    }
    Component {
        id: receive_page
        ReceivePage {
            context: self.context
            title: qsTrId('id_review')
            onCloseClicked: self.close()
        }
    }
}
