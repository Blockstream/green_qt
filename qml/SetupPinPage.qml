import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    signal finished(Context context)
    required property Context context
    property string pin

    PinDataController {
        id: controller
        context: self.context
        onFinished: self.finished(self.context)
    }
    StackView.onActivated: pin_field.forceActiveFocus()
    id: self
    padding: 60
    title: self.context?.wallet?.name ?? ''
    leftItem: Item {
    }
    contentItem: ColumnLayout {
        VSpacer {
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.preferredWidth: 0
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
        PinPadButton {
            Layout.alignment: Qt.AlignCenter
            enabled: pin_field.enabled
            onClicked: pin_field.openPad()
        }
        VSpacer {
        }
    }
    footerItem: RowLayout {
        spacing: 0
        Item {
            Layout.alignment: Qt.AlignCenter
            id: left_item
        }
        Item {
            Layout.preferredWidth: Math.max(UtilJS.effectiveWidth(right_item) - UtilJS.effectiveWidth(left_item), 0)
        }
        HSpacer {
        }
        ColumnLayout {
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/house.svg'
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                font.pixelSize: 12
                font.weight: 600
                text: qsTrId('id_make_sure_to_be_in_a_private')
            }
        }
        HSpacer {
        }
        Item {
            Layout.preferredWidth: Math.max(UtilJS.effectiveWidth(left_item) - UtilJS.effectiveWidth(right_item), 0)
        }
        LinkButton {
            Layout.alignment: Qt.AlignBottom
            id: right_item
            text: qsTrId('id_skip')
            visible: false
            // TODO: this button allows temporary login
            // visible: !self.pin
            onClicked: self.finished(self.context)
        }
    }
}
