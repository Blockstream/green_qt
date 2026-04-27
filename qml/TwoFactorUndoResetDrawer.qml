import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

WalletDrawer {
    required property Session session
    property string title: qsTrId('id_undo_2fa_dispute')
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
        id: next_action
        enabled: email_field.text.trim() !== ''
        onTriggered: controller.undoTwoFactorReset(email_field.text)
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
                spacing: 5
                Label {
                    text: qsTrId('id_if_you_initiated_the_2fa_reset')
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                }
                FieldTitle {
                    text: qsTrId('id_email')
                }
                TTextField {
                    Layout.fillWidth: true
                    id: email_field
                    onAccepted: next_action.trigger()
                }
                PrimaryButton {
                    Layout.minimumWidth: 150
                    Layout.alignment: Qt.AlignCenter
                    action: next_action
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
