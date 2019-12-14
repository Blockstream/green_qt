import QtQuick 2.12
import QtQuick.Controls 2.12
import '..'

Dialog {
    modal: true
    title: qsTr('id_mnemonic')

    Item {
        implicitWidth: view.implicitWidth
        implicitHeight: view.implicitHeight
        MnemonicView {
            id: view
            anchors.fill: parent
            mnemonic: wallet.mnemonic
        }
        MouseArea {
            id: mouse_area
            anchors.fill: parent
            hoverEnabled: true
        }
    }
    footer: ProgressBar {
        NumberAnimation on value {
            paused: mouse_area.containsMouse
            duration: 10000
            from: 1
            to: 0
            loops: 1
            onFinished: close()
        }
    }

}
