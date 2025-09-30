import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    signal finished(Context context)
    signal closeClicked()
    required property Context context
    property string pin

    PinDataController {
        id: controller
        context: self.context
        onFinished: self.finished(self.context)
        onUpdateFailed: error => {
            if (error) error_badge.raise(error)
            pin_field.clear()
        }

    }
    StackView.onActivated: pin_field.forceActiveFocus()
    id: self
    padding: 60
    title: self.context?.wallet?.name ?? ''
    leftItem: Item {
    }
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    Label {
        Layout.alignment: Qt.AlignCenter
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        font.pixelSize: 26
        font.weight: 600
        horizontalAlignment: Label.AlignHCenter
        text: self.pin && pin_field.enabled ? qsTrId('id_confirm_your_new_pin') : qsTrId('id_set_a_new_pin')
        wrapMode: Label.WordWrap
    }
    HSpacer {
        Layout.minimumHeight: 5
    }
    Label {
        Layout.alignment: Qt.AlignCenter
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        font.pixelSize: 14
        font.weight: 400
        horizontalAlignment: Label.AlignHCenter
        color: '#A0A0A0'
        text: qsTrId('id_youll_need_your_pin_to_log_in')
        wrapMode: Label.Wrap
    }
    PinField {
        Layout.alignment: Qt.AlignCenter
        Layout.topMargin: 36
        id: pin_field
        focus: true
        Component.onCompleted: forceActiveFocus()
        onPinEntered: (pin) => {
            if (self.pin) {
                if (self.pin === pin) {
                    pin_field.enabled = false
                    controller.update(pin)
                } else {
                    pin_field.enabled = false
                    self.pin = null
                    timer.start()
                    error_badge.error = qsTrId('id_pins_do_not_match_please_try')
                }
            } else {
                pin_field.enabled = false
                self.pin = pin
                timer.start()
            }
        }
        onPinChanged: {
            if (pin_field.pin.length > 0) {
                error_badge.clear()
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
    FixedErrorBadge {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 20
        id: error_badge
        pointer: false
        visible: true
    }
    PinPadButton {
        Layout.alignment: Qt.AlignCenter
        Layout.topMargin: 20
        enabled: pin_field.enabled
        target: pin_field
    }
    footer: RowLayout {
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
            Layout.bottomMargin: 20
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
