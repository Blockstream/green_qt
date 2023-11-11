import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    signal finished(Context context)
    required property Context context
    property string pin

    PinDataController {
        id: controller
        context: self.context
        onFinished: self.finished(self.context)
    }

    id: self
    padding: 60
    leftItem: Item {
    }
    contentItem: ColumnLayout {
        VSpacer {
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            font.family: 'SF Compact Display'
            font.pixelSize: 26
            font.weight: 600
            horizontalAlignment: Label.AlignHCenter
            text: self.pin && pin_field.enabled ? 'Confirm your 6-digit PIN' : 'Set up your 6-digit PIN'
            wrapMode: Label.WordWrap
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            font.family: 'SF Compact Display'
            font.pixelSize: 14
            font.weight: 400
            horizontalAlignment: Label.AlignHCenter
            opacity: 0.4
            text: `You'll need your PIN to log in to your wallet. This PIN secures the wallet on this device only.`
            wrapMode: Label.Wrap
        }
        PinField {
            Layout.alignment: Qt.AlignCenter
            Layout.bottomMargin: 54
            Layout.topMargin: 36
            id: pin_field
            focus: true
            onPinEntered: (pin) => {
                if (self.pin) {
                    if (self.pin === pin) {
                        pin_field.enabled = false
                        controller.update(pin)
                    } else {
                        pin_field.enabled = false
                        self.pin = null
                        timer.start()
                    }
                } else {
                    pin_field.enabled = false
                    self.pin = pin
                    timer.start()
                }
            }
        }
        Timer {
            id: timer
            interval: 300
            repeat: false
            onTriggered: {
                pin_field.clear()
                pin_field.enabled = true
            }
        }
        PinLoginPage.PinPadButton {
            Layout.alignment: Qt.AlignCenter
            enabled: pin_field.enabled
            onClicked: pin_field.openPad()
        }
        VSpacer {
        }
    }
    footer: StackViewPage.Footer {
        contentItem: ColumnLayout {
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/house.svg'
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                font.family: 'SF Compact Display'
                font.pixelSize: 12
                font.weight: 600
                text: qsTrId('id_make_sure_to_be_in_a_private')
            }
        }
    }
}
