import QtQuick 2.0
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.13

WalletDialog {
    id: self
    width: 320
    height: 400
    focus: true
    contentItem: PinView {
        id: pin_view
        property var new_pin
        property var new_pin_confirm
        property bool accept: false
        property string title: qsTrId('id_set_a_new_pin')
        state: "new_pin"
        states: [
            State {
                name: "new_pin"
                PropertyChanges { target: self; title: qsTrId('id_set_a_new_pin') }
            },
            State {
                name: "new_pin_confirm"
                PropertyChanges { target: self; title: qsTrId('id_verify_your_pin') }
            }
        ]
        onPinChanged: {
            if (pin.valid) {
                if (state=="new_pin") {
                    new_pin = pin
                    pin_view.clear()
                    state = "new_pin_confirm"
                }
                else if (state=="new_pin_confirm") {
                    new_pin_confirm = pin
                    if (pin_view.new_pin.value !== pin_view.new_pin_confirm.value) {
                        pin_view.accept = false
                        clear();
                        ToolTip.show(qsTrId('id_pins_do_not_match_please_try'), 1000);
                        state = "new_pin"
                    }
                    else {
                        pin_view.accept = true
                    }
                }
            }
        }
    }
    footer: Pane {
        topPadding: 16
        rightPadding: 16
        bottomPadding: 8
        background: null
        contentItem: RowLayout {
            Item {
                Layout.fillWidth: true
            }
            Button {
                enabled: pin_view.accept
                flat: true
                text: qsTrId('id_change_pin')
                onClicked: accept()
            }
        }
    }
    onAccepted: wallet.changePin(pin_view.pin.value)
    onClosed: destroy()
}
