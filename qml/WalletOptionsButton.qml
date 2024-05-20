import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

CircleButton {
    signal passphraseClicked()
    signal removeClicked()
    signal closeClicked()
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
            enabled: self.wallet?.login instanceof PinData
            text: qsTrId('id_login_with_bip39_passphrase')
            icon.source: 'qrc:/svg2/passphrase.svg'
            onClicked: {
                menu.close()
                self.passphraseClicked()
            }
        }
        GMenu.Separator {
        }
        GMenu.Item {
            text: qsTrId('id_remove_wallet')
            icon.source: 'qrc:/svg2/trash.svg'
            enabled: !!self.wallet
            onClicked: {
                menu.close()
                self.removeClicked()
            }
        }
        GMenu.Separator {
        }
        GMenu.Item {
            text: qsTrId('id_close')
            icon.source: 'qrc:/svg2/close.svg'
            onClicked: {
                menu.close()
                self.closeClicked()
            }
        }
    }
}
