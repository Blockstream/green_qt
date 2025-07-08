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
    clip: true
    header: null
    title: qsTrId('id_disable') + ' ' + UtilJS.twoFactorMethodLabel(self.method)
    onClosed: self.destroy()

    Overlay.modal: Rectangle {
        anchors.fill: parent
        color: 'black'
        opacity: 0.6
    }

    TwoFactorController {
        id: controller
        context: self.context
        session: self.session
        method: self.method
        onFinished: self.accept()
    }

    TaskPageFactory {
        monitor: controller.monitor
        target: stack_view
    }

    AnalyticsView {
        active: self.opened
        name: 'WalletSettings2FASetup'
        segmentation: AnalyticsJS.segmentationSession(Settings, self.context)
    }

    contentItem: GStackView {
        id: stack_view
        implicitWidth: {
            let w = 500
            for (let i = 0; i < stack_view.depth; i++) {
                const item = stack_view.get(i, StackView.DontLoad)
                if (item) w = Math.max(w, item.implicitWidth)
            }
            return w
        }
        implicitHeight: {
            let h = 450
            for (let i = 0; i < stack_view.depth; i++) {
                const item = stack_view.get(i, StackView.DontLoad)
                if (item) h = Math.max(h, item.implicitHeight)
            }
            return h
        }
        initialItem: StackViewPage {
            StackView.onActivated: controller.monitor.clear()
            title: self.title
            rightItem: CloseButton {
                onClicked: self.close()
            }
            contentItem: ColumnLayout {
                spacing: constants.s1
                Spacer {
                }
                MultiImage {
                    Layout.alignment: Qt.AlignCenter
                    foreground: `qrc:/svg3/2fa_${method}.svg`
                    width: 350
                    height: 200
                }
                Label {
                    Layout.alignment: Qt.AlignCenter
                    text: qsTrId('id_disable_s_twofactor').arg(UtilJS.twoFactorMethodLabel(self.method))
                }
                PrimaryButton {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.minimumWidth: 300
                    focus: true
                    text: qsTrId('id_next')
                    onClicked: controller.disable()
                }
                VSpacer {
                }
            }
        }
    }
}
