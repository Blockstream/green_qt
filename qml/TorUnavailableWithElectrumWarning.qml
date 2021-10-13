import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.0
import QtQuick.Controls 2.13

Loader {
    id: self
    required property Network network
    active: Settings.useTor && self.network && self.network.electrum
    sourceComponent: Label {
        padding: 8
        background: Rectangle {
            radius: 4
            color: constants.r500
        }
        font.capitalization: Font.AllUppercase
        font.styleName: 'Medium'
        font.pixelSize: 10
        text: qsTrId('Tor is not available yet for singlesig wallets')
    }
}
