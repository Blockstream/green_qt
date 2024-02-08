import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

WalletDialog {
    required property Session session
    required property string method

    id: self
    title: qsTrId('id_enable') + ' ' + UtilJS.twoFactorMethodLabel(self.method)
    clip: true
    header: null
    onClosed: self.destroy()

    Overlay.modal: Rectangle {
        anchors.fill: parent
        color: 'black'
        opacity: 0.6
    }

    AnalyticsView {
        active: true
        name: 'WalletSettings2FASetup'
        segmentation: AnalyticsJS.segmentationSession(Settings, self.wallet)
    }

    TwoFactorController {
        id: controller
        context: self.context
        session: self.session
        method: self.method
        onFinished: self.accept()
        onFailed: (error) => stack_view.replace(error_page, { error })
    }

    TaskPageFactory {
        title: self.title
        monitor: controller.monitor
        target: stack_view
    }

    contentItem: GStackView {
        id: stack_view
        initialItem: self.method === 'gauth' ? gauth_page : generic_page
        implicitWidth: Math.max(400, stack_view.currentItem.implicitWidth)
        implicitHeight: Math.max(400, stack_view.currentItem.implicitHeight)
    }

    Component {
        id: generic_page
        TwoFactorEnableGenericView {
            StackView.onActivated: controller.monitor.clear()
            title: self.title
            session: self.session
            method: self.method
            onNext: data => controller.enable(data)
            onClosed: self.close()
        }
    }

    Component {
        id: gauth_page
        TwoFactorEnableGAuthPage {
            StackView.onActivated: controller.monitor.clear()
            title: self.title
            session: self.session
            onNext: data => controller.enable(data)
            onClosed: self.close()
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
