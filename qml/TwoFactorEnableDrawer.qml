import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

WalletDrawer {
    required property Session session
    required property string method

    id: self
    property string title: qsTrId('id_enable') + ' ' + UtilJS.twoFactorMethodLabel(self.method)

    Overlay.modal: Rectangle {
        anchors.fill: parent
        color: 'black'
        opacity: 0.6
    }

    AnalyticsView {
        active: true
        name: 'WalletSettings2FASetup'
        segmentation: AnalyticsJS.segmentationSession(Settings, self.context)
    }

    TwoFactorController {
        id: controller
        context: self.context
        session: self.session
        method: self.method
        onFinished: self.close()
        onFailed: (error) => stack_view.replace(error_page, { error })
    }

    TaskPageFactory {
        title: self.title
        monitor: controller.monitor
        target: stack_view
    }

    contentItem: GStackView {
        id: stack_view
        initialItem: {
            switch (self.method) {
            case 'gauth':
                return gauth_page
            case 'sms':
            case 'phone':
                return phone_page
            default:
                return generic_page
            }
        }
    }

    Component {
        id: generic_page
        TwoFactorEnableGenericView {
            StackView.onActivated: controller.monitor.clear()
            title: self.title
            session: self.session
            method: self.method
            onNext: data => controller.enable(data)
            onCloseClicked: self.close()
        }
    }

    Component {
        id: phone_page
        TwoFactorEnablePhoneView {
            StackView.onActivated: controller.monitor.clear()
            title: self.title
            session: self.session
            method: self.method
            onNext: data => controller.enable(data)
            onCloseClicked: self.close()
        }
    }

    Component {
        id: gauth_page
        TwoFactorEnableGAuthPage {
            StackView.onActivated: controller.monitor.clear()
            title: self.title
            session: self.session
            onNext: data => controller.enable(data)
            onCloseClicked: self.close()
        }
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
