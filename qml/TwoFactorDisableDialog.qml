import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

ControllerDialog {
    id: dialog
    property string method
    title: qsTrId('id_set_up_twofactor_authentication')
    doneText: qsTrId('id_disabled')

    controller: Controller {
        wallet: dialog.wallet
    }

    initialItem: RowLayout {
        property list<Action> actions: [
            Action {
                text: qsTrId('id_next')
                onTriggered: controller.disableTwoFactor(method)
            }
        ]
        spacing: constants.s1
        Image {
            source: `qrc:/svg/2fa_${method}.svg`
            sourceSize.width: 32
            sourceSize.height: 32
        }
        Label {
            text: qsTrId('id_disable_s_twofactor').arg(method)
        }
    }

    AnalyticsView {
        active: dialog.opened
        name: 'WalletSettings2FASetup'
        segmentation: segmentationSession(dialog.wallet)
    }
}
