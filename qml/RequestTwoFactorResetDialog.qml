import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

ControllerDialog {
    id: dialog
    title: qsTrId('id_request_twofactor_reset')
    controller: Controller {
        wallet: dialog.wallet
    }
    initialItem: ColumnLayout {
        spacing: constants.s2
        property list<Action> actions: [
            Action {
                enabled: email_field.text.trim() !== ''
                text: qsTrId('id_next')
                onTriggered: controller.requestTwoFactorReset(email_field.text)
            }
        ]        
        Label {
            text: qsTrId('id_the_new_email_will_be_used_for')
            wrapMode: Text.Wrap
            Layout.maximumWidth: 400
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
        GTextField {
            id: email_field
            Layout.fillWidth: true
            placeholderText: qsTrId('id_enter_new_email')
        }
    }

    AnalyticsView {
        active: dialog.opened
        name: 'WalletSettings2FAReset'
        segmentation: segmentationSession(dialog.wallet)
    }
}
