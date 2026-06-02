import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

WalletDrawer {
    required property Session session

    id: self
    property string title: qsTrId('id_set_an_email_for_recovery')
    edge: Qt.RightEdge
    minimumContentWidth: 460
    Controller {
        id: controller
        context: self.context
        onFailed: (error) => error_badge.error = error || "The action can't be completed"
        onFinished: self.close()
    }
    contentItem: GStackView {
        initialItem: StackViewPage {
            title: self.title
            rightItem: CloseButton {
                onClicked: self.close()
            }
            contentItem: StackLayout {
                id: stack_layout
                currentIndex: auth_handler_loader.active ? 1 : 0
                Page {
                    id: form_page
                    background: null
                    leftPadding: 0
                    rightPadding: 0
                    topPadding: 0
                    bottomPadding: 0
                    contentItem: ColumnLayout {
                        spacing: 16
                        Label {
                            Layout.fillWidth: true
                            Layout.topMargin: 20
                            Layout.bottomMargin: 6
                            text: qsTrId('id_set_up_an_email_to_get')
                            wrapMode: Text.WordWrap
                        }
                        GTextField {
                            id: email_field
                            Layout.fillWidth: true
                            Layout.preferredHeight: 52
                            placeholderText: qsTrId('id_enter_your_email_address')
                        }
                        FixedErrorBadge {
                            Layout.fillWidth: true
                            id: error_badge
                        }
                        PrimaryButton {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.minimumWidth: 150
                            enabled: email_field.text.trim() !== '' && (controller.monitor?.idle ?? true)
                            text: qsTrId('id_next')
                            onClicked: {
                                error_badge.clear()
                                controller.setSessionRecoveryEmail(self.session, email_field.text.trim())
                            }
                        }
                        VSpacer {
                        }
                    }
                }
                AnimLoader {
                    readonly property AuthHandlerTask task: {
                        const groups = controller.monitor?.groups ?? []
                        for (let i = 0; i < groups.length; i++) {
                            const group = groups[i]
                            const tasks = group.tasks
                            for (let j = 0; j < tasks.length; j++) {
                                const task = tasks[j]
                                if (!(task instanceof AuthHandlerTask)) continue
                                if (task.status !== Task.Active) continue
                                return task
                            }
                        }
                        return null
                    }
                    animated: true
                    active: !!task
                    sourceComponent: AuthHandlerTaskView {
                        task: auth_handler_loader.task
                    }
                    id: auth_handler_loader
                }
            }
        }
    }
}
