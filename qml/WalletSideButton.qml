import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Layouts 1.12

SideButton {
    id: self
    required property Wallet wallet
    location: `/${wallet.network.key}/${wallet.id}`
    text: wallet.name
    busy: wallet.activities.length > 0
    ready: wallet.ready
    icon.width: 16
    icon.height: 16
    leftPadding: 32
    icon.source: wallet.network.electrum ? 'qrc:/svg/key.svg' : 'qrc:/svg/multi-sig.svg'
    visible: !Settings.collapseSideBar
    DeviceImage {
        Layout.minimumWidth: paintedWidth
        sourceSize.height: 16
        parent: self.contentItem
        visible: wallet.device
        device: wallet.device
    }
}
