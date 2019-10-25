import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

import './views'

Item {
    StackView {
        id: stack_view
        anchors.centerIn: parent
        clip: true
        implicitWidth: currentItem.implicitWidth
        implicitHeight: currentItem.implicitHeight

        initialItem: NetworkPage {
            id: network_page
            accept: Action {
                onTriggered: stack_view.push(mnemonic_editor)
            }
        }
    }

    property Item mnemonic_editor: MnemonicEditor {
        accept: Action {
            text: qsTr('id_next')
            onTriggered: WalletManager.signup('', false, network_page.network, 'recover', mnemonic, '111111');
        }
    }
}
