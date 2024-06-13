import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

import "util.js" as UtilJS

AbstractDrawer {
    required property Context context
    readonly property int count: self.context.notifications.length

    onCountChanged: if (self.count === 0) self.close()
    onClosed: {
        controller.updateSeen()
        stack_view.pop(initial_page)
    }

    NotificationsController {
        id: controller
        context: self.context
    }

    TaskPageFactory {
        title: qsTrId('id_notifications')
        monitor: controller.monitor
        target: stack_view
    }

    id: self
    edge: Qt.RightEdge
    minimumContentWidth: 450
    contentItem: GStackView {
        id: stack_view
        initialItem: StackViewPage {
            id: initial_page
            title: qsTrId('id_notifications')
            rightItem: CloseButton {
                onClicked: self.close()
            }
            contentItem: TListView {
                id: list_view
                clip: true
                spacing: 10
                model: NotificationsModel {
                    source: controller.model
                }
                delegate: NotificationDelegate {
                }
            }
        }
    }

    component NotificationDelegate: ItemDelegate {
        required property Notification notification
        id: delegate
        enabled: !delegate.notification.busy
        width: delegate.ListView.view.width
        text: delegate.notification.message
        background: Rectangle {
            id: r1
            anchors.fill: parent
            color: '#222226'
            radius: 5
        }
        topPadding: 18
        leftPadding: 18
        rightPadding: 18
        bottomPadding: 18
        contentItem: RowLayout {
            spacing: 5
            Loader {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignCenter
                property Notification notification: delegate.notification
                sourceComponent: {
                    if (delegate.notification instanceof SystemNotification) {
                        return system_notification
                    } else if (delegate.notification instanceof TwoFactorResetNotification) {
                        return two_factor_reset_notification
                    }
                    return null
                }
            }
            ColumnLayout {
                Layout.fillWidth: false
                VSpacer {
                }
                CloseButton {
                    visible: delegate.notification.dismissable
                    opacity: 0.6
                    onClicked: delegate.notification.dismiss()
                }
                ProgressIndicator {
                   Layout.minimumWidth: 24
                   Layout.minimumHeight: 24
                   indeterminate: delegate.notification.busy
                   visible: delegate.notification.busy
                }
                VSpacer {
                }
            }
        }
    }

    Component {
        id: system_notification
        ColumnLayout {
            AnalyticsView {
                active: true
                name: 'SystemMessage'
            }
            spacing: 0
            RowLayout {
                Layout.bottomMargin: 10
                Image {
                    Layout.preferredHeight: 24
                    Layout.preferredWidth: 24
                    source: UtilJS.iconFor(notification.network)
                }
                Label {
                    color: '#FFF'
                    font.pixelSize: 16
                    opacity: 0.6
                    text: notification.network.displayName
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                color: '#FFF'
                font.pixelSize: 18
                font.weight: 500
                text: notification.message
                textFormat: Label.MarkdownText
                wrapMode: Label.Wrap
                onLinkActivated: Qt.openUrlExternally(link)
            }
            Collapsible {
                Layout.fillWidth: true
                animationVelocity: 300
                collapsed: notification.accepted
                ColumnLayout {
                    width: parent.width
                    y: 10
                    RowLayout {
                        CheckBox {
                            Layout.alignment: Qt.AlignCenter
                            id: confirm_checkbox
                        }
                        Label {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            color: '#FFF'
                            text: qsTrId('id_i_confirm_i_have_read_and')
                            wrapMode: Label.Wrap
                        }
                    }
                    RegularButton {
                        Layout.alignment: Qt.AlignRight
                        enabled: confirm_checkbox.checked
                        font.capitalization: Font.Capitalize
                        text: qsTrId('id_accept').toLowerCase()
                        onClicked: notification.accept(controller.monitor)
                    }
                }
            }
        }
    }
    Component {
        id: two_factor_reset_notification
        TwoFactorResetNotificationView {
        }
    }

    component TwoFactorResetNotificationView: ColumnLayout {
        readonly property Session session: notification.context.getOrCreateSession(notification.network)
        id: view
        spacing: 0
        RowLayout {
            Layout.bottomMargin: 10
            Image {
                Layout.preferredHeight: 24
                Layout.preferredWidth: 24
                source: UtilJS.iconFor(notification.network)
            }
            Label {
                color: '#FFF'
                font.pixelSize: 16
                opacity: 0.6
                text: notification.network.displayName
            }
        }
        Label {
            Layout.bottomMargin: 10
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            color: '#FFF'
            font.pixelSize: 14
            font.weight: 500
            text: qsTrId('id_twofactor_reset_in_progress')
            wrapMode: Label.WordWrap
        }
        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            color: '#FFF'
            opacity: 0.8
            text: {
                if (view.session.config.twofactor_reset?.is_active ?? false) {
                    return qsTrId('id_your_wallet_is_locked_for_a').arg(view.session.config.twofactor_reset.days_remaining)
                } else {
                    return ''
                }
            }
            wrapMode: Label.WordWrap
        }
    }
}
