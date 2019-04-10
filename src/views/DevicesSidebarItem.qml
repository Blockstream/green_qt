import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.13

SidebarItem {
    title: qsTr('DEVICES')

    Repeater {
        model: DeviceManager.devices

        delegate: ItemDelegate {
            text: 'LEDGER NANO X' //modelData.name
            width: parent.width
        }
    }
}
