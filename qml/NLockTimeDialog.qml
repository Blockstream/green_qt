import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

WalletDrawer {
    required property Session session

    id: self
    property string title: qsTrId('id_set_timelock')
    edge: Qt.RightEdge
    minimumContentWidth: 520
    Controller {
        id: controller
        context: self.context
        onFailed: (error) => error_badge.error = error
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
                        id: form
                        Label {
                            Layout.topMargin: 20
                            Layout.bottomMargin: 8
                            text: qsTrId('id_redeem_your_deposited_funds')
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                        Label {
                            text: qsTrId('id_value_must_be_between_144_and')
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                        RowLayout {
                            Layout.alignment: Qt.AlignCenter
                            GTextField {
                                id: nlocktime_days
                                text: Math.round(self.session.settings.nlocktime / 144 || 0)
                                Layout.preferredHeight: 52
                                validator: IntValidator { bottom: 1; top: 200000 / 144; }
                                onTextChanged: {
                                    if (activeFocus) nlocktime_blocks.text = Math.round(text * 144)
                                }
                                horizontalAlignment: Qt.AlignRight
                                Layout.alignment: Qt.AlignBaseline
                            }
                            Label {
                                text: qsTrId('id_days') + ' ≈ '
                                Layout.alignment: Qt.AlignBaseline
                            }
                            GTextField {
                                id: nlocktime_blocks
                                text: self.session.settings.nlocktime || 0
                                Layout.preferredHeight: 52
                                validator: IntValidator { bottom: 144; top: 200000; }
                                onTextChanged: {
                                    if (activeFocus) nlocktime_days.text = Math.round(text / 144)
                                }
                                horizontalAlignment: Qt.AlignRight
                                Layout.alignment: Qt.AlignBaseline
                            }
                            Label {
                                text: qsTrId('id_blocks')
                                Layout.alignment: Qt.AlignBaseline
                            }
                        }
                        FixedErrorBadge {
                            Layout.fillWidth: true
                            id: error_badge
                        }
                        PrimaryButton {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.minimumWidth: 150
                            enabled: nlocktime_blocks.acceptableInput
                                     && Number.parseInt(nlocktime_blocks.text) !== self.session.settings.nlocktime
                                     && (controller.monitor?.idle ?? true)
                            text: qsTrId('id_next')
                            onClicked: {
                                error_badge.clear()
                                controller.changeSessionSettings(self.session, { nlocktime: Number.parseInt(nlocktime_blocks.text) })
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
