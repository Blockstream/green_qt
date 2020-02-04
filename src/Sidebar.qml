import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13

import './views'

ScrollView {
    id: scroll_view
    clip: true

    Column {
        WalletsSidebarItem {
            width: scroll_view.width
        }
    }
}
