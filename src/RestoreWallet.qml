import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

Page {
    header: RowLayout {
        TextField {
            id: name_field
        }

        PinView {
            id: pin
        }

        FlatButton {
            text: "GO"
            onClicked: wallet.recover(name_field.text, text_area.text, pin.pin)
            enabled: wallet.online && pin.valid && name_field.text.length > 0
        }
    }

    Wallet {
        id: wallet
    }

    TextArea {
        id: text_area
        anchors.fill: parent
        text: "south crack marine tourist rain estate young camp permit soccer wink romance claw critic govern execute fiber brass nose lobster give pig energy shield"
    }
}
