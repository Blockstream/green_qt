import Blockstream.Green
import Blockstream.Green.Core
import QtQuick

AbstractDrawer {
    signal deviceSelected(JadeDevice device, Context context)
    signal loginFinished(Context context)
    // When set, only a device holding this wallet is accepted.
    property Wallet wallet: null
    // When set, the device is unlocked on this context instead of a new one.
    property Context context: null
    property bool qrEnabled: false
    onClosed: self.destroy()
    id: self
    edge: Qt.RightEdge
    contentItem: GStackView {
        title: self.wallet?.name ?? qsTrId('id_connect_jade')
        initialItem: ConnectJadePage {
            wallet: self.wallet
            context: self.context
            qrEnabled: self.qrEnabled
            onDeviceSelected: (device, context) => self.deviceSelected(device, context)
            onLoginFinished: (context) => self.loginFinished(context)
            onCloseClicked: self.close()
        }
    }
}
