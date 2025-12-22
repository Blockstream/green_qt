import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

WalletDrawer {
    required property Session session
    property string title: qsTrId('id_request_twofactor_reset')
    AnalyticsView {
        active: self.visible
        name: 'WalletSettings2FAReset'
        segmentation: AnalyticsJS.segmentationSession(Settings, controller.context)
    }
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
    Action {
        id: request_twofactor_reset_action
        enabled: email_field.text.trim() !== ''
        onTriggered: controller.requestTwoFactorReset(email_field.text)
    }
    id: self
    contentItem: GStackView {
        id: stack_view
        initialItem: StackViewPage {
            rightItem: CloseButton {
                onClicked: self.close()
            }
            title: self.title
            contentItem: ColumnLayout {
                spacing: constants.s1
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
