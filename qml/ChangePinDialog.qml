import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS

ControllerDialog {
    property string pin
    property bool changed: false

    id: self
    title: qsTrId('id_change_pin')

    controller: Controller {
        id: controller
        context: self.context
        onFinished: self.accept()
    }

    AnalyticsView {
        active: self.opened
        name: 'WalletSettingsChangePIN'
        segmentation: AnalyticsJS.segmentationSession(self.wallet)
    }

    RowLayout {
        Spacer {
        }
        PinView {
            id: pin_view
            focus: true
            label: self.pin ? qsTrId('id_verify_your_pin') : qsTrId('id_set_a_new_pin')
            onPinEntered: (pin) => {
                if (self.pin) {
                    if (self.pin === pin) {
                        controller.changePin(self.pin)
                    } else {
                        pin_view.ToolTip.show(qsTrId('id_pins_do_not_match_please_try'), 1000)
                        pin_view.clear()
                        self.pin = null
                    }
                } else {
                    self.pin = pin
                    pin_view.clear()
                }
            }
        }
        HSpacer {
        }
    }
}
