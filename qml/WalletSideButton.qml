import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Layouts

SideButton {
    id: self
    required property Wallet wallet
    isCurrent: navigation.param.wallet === self.wallet.id
    onClicked: navigation.set({ view: wallet.network.key, wallet: self.wallet.id })
    text: wallet.name
//    busy: wallet.activities.length > 0
    icon.width: 16
    icon.height: 16
    leftPadding: 32
    icon.source: wallet.network.electrum ? 'qrc:/svg/key.svg' : 'qrc:/svg/multi-sig.svg'
    visible: !Settings.collapseSideBar
    Loader {
        parent: self.contentItem
        active: 'type' in wallet.deviceDetails
        visible: active
        sourceComponent: DeviceBadge {
            device: wallet.context?.device
            details: wallet.deviceDetails
        }
    }
}
