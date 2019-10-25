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

        initialItem: RowLayout {
            FlatButton {
                text: 'GO'
                onClicked: stack_view.push(mnemonic_view)
            }
        }
    }

    Component {
        id: mnemonic_view

        MnemonicEditor { }
    }
}
