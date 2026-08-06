import Blockstream.Green
import Blockstream.Green.Core
import QtQuick

import "util.js" as UtilJS

WalletDrawer {
    id: self
    minimumContentWidth: 450
    contentItem: GStackView {
        id: stack_view
        title: qsTrId('id_swap')
        initialItem: UtilJS.isSwapAvailable('bitcoin', 'liquid') ? chain_swap_create_page : swaps_unavailable_page
    }

    Component {
        id: chain_swap_create_page
        ChainSwapCreatePage {
            context: self.context
            onCloseClicked: self.close()
        }
    }

    Component {
        id: swaps_unavailable_page
        SwapsUnavailablePage {
            onCloseClicked: self.close()
        }
    }
}
