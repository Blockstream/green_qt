import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12
import './views'

FocusScope {
    activeFocusOnTab: false
    focus: false

    enabled: wallet.online && !wallet.authenticating

    ColumnLayout {
        spacing: 16
        anchors.centerIn: parent

        opacity: wallet.authenticating ? 0.5 : 1

        FlatButton {
            visible: false
            text: "TEST"
            onClicked: wallet.test()
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr(`ENTER PIN FOR WALLET ${wallet.name}`)
        }

        PinView {
            id: pin_view
            focus: true
            onPinChanged: if (valid) {
                wallet.login(pin)
                wallet.reload()
            }
        }
    }

    BusyIndicator {
        anchors.centerIn: parent
        opacity: !wallet.online || wallet.authenticating ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: 300 }
        }
    }

}
