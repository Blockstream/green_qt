import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

WalletDrawer {
    required property Session session
    property string title: qsTrId('id_cancel_twofactor_reset')
    Component.onCompleted: controller.cancelTwoFactorReset()
    SessionController {
        id: controller
        context: self.context
        session: self.session
        onFinished: self.close()
        onFailed: (error) => stack_view.replace(error_page, { error })
    }
    TaskPageFactory {
        title: self.title
        monitor: controller.monitor
        target: stack_view
    }

    id: self
    contentItem: GStackView {
        id: stack_view
    }

    Component {
        id: error_page
        ErrorPage {
            rightItem: CloseButton {
                onClicked: self.close()
            }
        }
    }
}
