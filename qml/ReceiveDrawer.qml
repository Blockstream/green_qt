import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

WalletDrawer {
    id: self
    preferredContentWidth: stack_view.currentItem.implicitWidth
    minimumContentWidth: 400
    contentItem: GStackView {
        id: stack_view
        initialItem: ReceiveAccountAssetSelector {
            context: self.context
            title: qsTrId('id_receive')
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
            onCloseClicked: self.close()
        }
    }
}
