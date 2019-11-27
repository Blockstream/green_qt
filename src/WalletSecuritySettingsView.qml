import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

Panel {
    icon: 'assets/svg/security.svg'
    title: qsTr('SECUTIRY')

    TextField {
        id: code
        placeholderText: 'SMS CODE'
        visible: false
    }

    FlatButton {
        visible: code.visible
        text: 'VERIFY CODE'
        onClicked: ctrl.resolveCode(code.text)
    }

    FlatButton {
        text: 'ENABLE 2F SMS'
        TwoFactorController {
            id: ctrl
        }
        onClicked: ctrl.go()
    }
    FlatButton {
        text: 'ENABLE 2F EMAIL'
        onClicked: ctrl.enableEmail()
    }
    FlatButton {
        text: 'DISABLE 2F SMS'
        onClicked: ctrl.disable();
    }

    RowLayout {
        FlatButton {
            id: ddd
            checkable: true
            text: qsTr('SHOW MNEMONIC')
        }
        ProgressBar {
            visible: ddd.checked
            NumberAnimation on value {
                id: caralho
                duration: 15000
                from: 1
                to: 0
                loops: 1
                running: ddd.checked
                onFinished: ddd.checked = false
            }
        }
    }

    MnemonicView {
        Layout.fillWidth: true
        Layout.minimumHeight: 300

        visible: ddd.checked
        mnemonic: wallet.mnemonic
    }
}
