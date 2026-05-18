import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS

WalletDrawer {
    required property Session session
    required property bool dispute
    property string title: {
        if (self.dispute) {
            return qsTrId('id_dispute_twofactor_reset')
        }
        return qsTrId('id_request_twofactor_reset')
    }
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
        onTriggered: controller.requestTwoFactorReset(email_field.text, self.dispute)
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
                    text: {
                        if (self.dispute) {
                            return qsTrId('id_if_you_did_not_request_the')
                        }
                        return qsTrId('id_the_new_email_will_be_used_for')
                    }
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
                    Layout.minimumWidth: 150
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
