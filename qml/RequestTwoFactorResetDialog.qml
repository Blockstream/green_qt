import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

WalletDialog {
    required property Session session

    id: self
    clip: true
    header: null
    onClosed: self.destroy()
    Overlay.modal: Rectangle {
        anchors.fill: parent
        color: 'black'
        opacity: 0.6
    }
    AnalyticsView {
        active: self.opened
        name: 'WalletSettings2FAReset'
        segmentation: AnalyticsJS.segmentationSession(Settings, controller.context)
    }
    SessionController {
        id: controller
        context: self.context
        session: self.session
        onFinished: self.accept()
        onFailed: (error) => stack_view.replace(error_page, { error })
    }
    TaskPageFactory {
        title: self.title
        monitor: controller.monitor
        target: stack_view
    }
    Action {
        id: request_twofactor_reset_action
        enabled: email_field.text.trim() !== ''
        onTriggered: controller.requestTwoFactorReset(email_field.text)
    }
    contentItem: GStackView {
        id: stack_view
        initialItem: StackViewPage {
            rightItem: CloseButton {
                onClicked: self.reject()
            }
            title: 'Request Two-Factor Reset'
            contentItem: ColumnLayout {
                spacing: constants.s1
                VSpacer {
                }
                Label {
                    text: qsTrId('id_the_new_email_will_be_used_for')
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                }
                SectionLabel {
                    text: qsTrId('id_enter_new_email')
                }
                TTextField {
                    Layout.fillWidth: true
                    id: email_field
                    onAccepted: request_twofactor_reset_action.trigger()
                }
                PrimaryButton {
                    Layout.alignment: Qt.AlignCenter
                    action: request_twofactor_reset_action
                    text: qsTrId('id_next')
                }
                VSpacer {
                }
            }
        }
        implicitWidth: {
            let w = 400
            for (let i = 0; i < stack_view.depth; i++) {
                const item = stack_view.get(i, StackView.DontLoad)
                if (item) w = Math.max(w, item.implicitWidth)
            }
            return w
        }
        implicitHeight: {
            let h = 400
            for (let i = 0; i < stack_view.depth; i++) {
                const item = stack_view.get(i, StackView.DontLoad)
                if (item) h = Math.max(h, item.implicitHeight)
            }
            return h
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
