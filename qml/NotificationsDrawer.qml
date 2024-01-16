import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

AbstractDrawer {
    required property Context context
    readonly property int count: self.context.notifications.length

    onCountChanged: if (self.count === 0) self.close()
    onClosed: controller.updateSeen()

    NotificationsController {
        id: controller
        context: self.context
    }

    TaskPageFactory {
        monitor: controller.monitor
        target: stack_view
    }

    id: self
    edge: Qt.RightEdge
    minimumContentWidth: 450
    contentItem: GStackView {
        id: stack_view
        initialItem: StackViewPage {
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
            Label {
                Layout.bottomMargin: 10
                color: '#FFF'
                font.pixelSize: 12
                opacity: 0.6
                text: notification.network.displayName
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
                    PrimaryButton {
                        enabled: confirm_checkbox.checked
                        font.capitalization: Font.Capitalize
                        text: qsTrId('id_accept').toLowerCase()
                        onClicked: notification.accept(controller.monitor)
                    }
                }
            }
        }
    }
}
