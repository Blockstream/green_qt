import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS

ControllerDialog {
    property string method
    required property Session session

    id: self
    title: qsTrId('id_set_up_twofactor_authentication')

    controller: TwoFactorController {
        id: controller
        context: self.context
        onFinished: self.accept()
    }

    AnalyticsView {
        active: self.opened
        name: 'WalletSettings2FASetup'
        segmentation: AnalyticsJS.segmentationSession(self.wallet)
    }

    ColumnLayout {
        spacing: constants.s1
        Spacer {
        }
        Image {
            Layout.alignment: Qt.AlignCenter
            source: `qrc:/svg/2fa_${method}.svg`
            sourceSize.width: 64
            sourceSize.height: 64
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            text: qsTrId('id_disable_s_twofactor').arg(method.toUpperCase())
        }
        GButton {
            Layout.alignment: Qt.AlignCenter
            highlighted: true
            text: qsTrId('id_next')
            focus: true
            onClicked: controller.disable(method)
        }
        VSpacer {
        }
    }
}
