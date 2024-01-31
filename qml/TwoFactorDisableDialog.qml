import Blockstream.Green
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
        segmentation: AnalyticsJS.segmentationSession(self.wallet)
    }

    contentItem: GStackView {
        id: stack_view
        implicitWidth: Math.max(500, stack_view.currentItem.implicitWidth)
        implicitHeight: Math.max(450, stack_view.currentItem.implicitHeight)
        initialItem: StackViewPage {
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
                    foreground: `qrc:/png/2fa_${method}.png`
                    width: 350
                    height: 200
                }
                Label {
                    Layout.alignment: Qt.AlignCenter
                    text: qsTrId('id_disable_s_twofactor').arg(method.toUpperCase())
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
