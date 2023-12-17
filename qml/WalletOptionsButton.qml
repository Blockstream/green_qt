import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

CircleButton {
    signal removeClicked()
    required property Wallet wallet
    id: self
    icon.source: 'qrc:/svg/3-dots.svg'
    onClicked: menu.open()
    enabled: !menu.visible
    GMenu {
        id: menu
        x: self.width * 0.5 - menu.width * 0.85
        y: self.height + 8
        pointerX: 0.85
        pointerY: 0
        GMenu.Item {
            text: qsTrId('id_remove_wallet')
            onClicked: {
                menu.close()
                self.removeClicked()
            }
        }
    }
}
