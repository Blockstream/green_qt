import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS

ControllerDialog {
    id: self
    title: qsTrId('id_request_twofactor_reset')
    controller: Controller {
        id: controller
        context: self.wallet.context
    }
    Action {
        id: request_twofactor_reset_action
        enabled: email_field.text.trim() !== ''
        onTriggered: controller.requestTwoFactorReset(email_field.text)
    }

    ColumnLayout {
        spacing: constants.s1
        VSpacer {
        }
        Label {
            text: qsTrId('id_the_new_email_will_be_used_for')
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            Layout.preferredWidth: 0
        }
        GTextField {
            id: email_field
            Layout.fillWidth: true
            placeholderText: qsTrId('id_enter_new_email')
            onAccepted: request_twofactor_reset_action.trigger()
        }
        GButton {
            Layout.alignment: Qt.AlignCenter
            action: request_twofactor_reset_action
            large: true
            text: qsTrId('id_next')
        }
        VSpacer {
        }
    }

    AnalyticsView {
        active: self.opened
        name: 'WalletSettings2FAReset'
        segmentation: AnalyticsJS.segmentationSession(self.wallet)
    }
}
