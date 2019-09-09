import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

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

        PinField {
            id: pin_view
            focus: true
            onPinChanged: {
                console.log("LOGON WITH PIN ", pin, valid)
                if (pin.length === 6) {
                    console.log("LOGON WITH PIN ", pin)
                    wallet.login(pin)
                    wallet.reload()
                }
            }
        }

        GridLayout {
            Keys.forwardTo: pin_view

            Layout.alignment: Qt.AlignHCenter

            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }

            columns: 3
            Repeater {
                model: 9
                FlatButton {
                    text: modelData + 1
                    onClicked: pin_view.addDigit(modelData + 1)
                }
            }

            FlatButton {
                text: qsTr("UNDO")
                onClicked: pin_view.removeDigit()
            }
            FlatButton {
                text: qsTr("0")
                onClicked: pin_view.addDigit(0)
            }
            FlatButton {
                text: qsTr("CLEAR")
                onClicked: pin_view.clear()
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
