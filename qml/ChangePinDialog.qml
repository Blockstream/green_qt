import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS

ControllerDialog {
    property bool changed: false

    id: self
    title: controller.pin ? qsTrId('id_verify_your_pin') : qsTrId('id_set_a_new_pin')
    onOpened: pin_view.forceActiveFocus()
    controller: ChangePinController {
        wallet: self.wallet
        onFinished: self.changed = true
    }
    AnalyticsView {
        active: self.opened
        name: 'WalletSettingsChangePIN'
        segmentation: AnalyticsJS.segmentationSession(self.wallet)
    }
    initialItem: RowLayout {
        HSpacer {
        }
        PinView {
            id: pin_view
            focus: true
            onPinEntered: (pin) => {
                if (controller.pin) {
                    if (controller.pin !== pin) {
                        ToolTip.show(qsTrId('id_pins_do_not_match_please_try'), 1000)
                        pin_view.clear()
                    }
                } else {
                    controller.pin = pin
                    pin_view.clear()
                }
            }
        }
        HSpacer {
        }
    }
    footer: DialogFooter {
        HSpacer {
        }
        GButton {
            visible: !self.changed
            highlighted: true
            enabled: controller.pin && controller.pin === pin_view.pin.value
            text: qsTrId('id_change_pin')
            onClicked: controller.accept()
        }
        GButton {
            visible: pin_view.valid && self.changed
            highlighted: true
            text: qsTrId('id_ok')
            onClicked: self.accept()
        }
        HSpacer {
        }
    }
    onClosed: destroy()
}
