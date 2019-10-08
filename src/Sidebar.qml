import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13

import './views'


ScrollView {
    id: scroll_view
    clip: true
    anchors.fill: parent
    anchors.leftMargin: 8

    Column {
        spacing: 16

        WalletsSidebarItem {
            width: scroll_view.width
        }

        DevicesSidebarItem {
            width: scroll_view.width
        }
    }
}
