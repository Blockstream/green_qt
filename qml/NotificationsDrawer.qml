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

    objectName: "NotificationsDrawer"
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
            contentItem: StackLayout {
                currentIndex: (self.context.notifications.length === 0 && !update_controller.notification) ? 0 : 1
                ColumnLayout {
                    spacing: 16
                    VSpacer {
                        Layout.fillWidth: true
                    }
                    MultiImage {
                        Layout.alignment: Qt.AlignCenter
                        foreground: 'qrc:/svg2/notifications.svg'
                        fill: false
                        center: true
                        width: 300
                        height: 182
                    }
                    Label {
                        Layout.alignment: Qt.AlignCenter
                        Layout.fillWidth: true
                        Layout.maximumWidth: 200
                        font.pixelSize: 18
                        font.weight: 700
                        horizontalAlignment: Label.AlignHCenter
                        text: `You don't have any notification`
                        wrapMode: Label.Wrap
                    }
                    Label {
                        Layout.alignment: Qt.AlignCenter
                        Layout.fillWidth: true
                        Layout.maximumWidth: 300
                        font.pixelSize: 12
                        font.weight: 400
                        horizontalAlignment: Label.AlignHCenter
                        opacity: 0.6
                        text: `You don't have any notifications right now; we'll let you know as soon as there's something new.`
                        wrapMode: Label.Wrap
                    }
                    VSpacer {
                    }
                }
                ColumnLayout {
                    spacing: 10
                    Loader {
                        Layout.fillWidth: true
                        active: !!update_controller.notification
                        visible: !!update_controller.notification
                        sourceComponent: UpdateNotificationView {
                            notification: update_controller.notification
                        }
                    }
                    TListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
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
        }
    }

    component NotificationDelegate: ItemDelegate {
        required property Notification notification
        id: delegate
        enabled: !delegate.notification.busy
        width: delegate.ListView.view.width
        background: null
        topPadding: 0
        leftPadding: 0
        rightPadding: 0
        bottomPadding: 0
        contentItem: Loader {
            property Notification _notification: delegate.notification
            sourceComponent: {
                if (delegate.notification instanceof SystemNotification) {
                    return system_notification
                } else if (delegate.notification instanceof OutageNotification) {
                    return outage_notification
                } else if (delegate.notification instanceof WarningNotification) {
                    return warning_notification
                } else if (delegate.notification instanceof TwoFactorResetNotification) {
                    return two_factor_reset_notification
                } else if (delegate.notification instanceof TwoFactorExpiredNotification) {
                    return two_factor_expired_notification
                } else if (delegate.notification instanceof BackupNotification) {
                    return backup_notification
                }
                return null
            }
        }
    }

    Component {
        id: backup_page
        BackupPage {
            onCloseClicked: self.close()
            onCompleted: stack_view.pop(null)
        }
    }

    component NotificationItem: AbstractButton {
        property Notification notification: _notification
        property color backgroundColor: '#262626'
        id: item
        topPadding: 18
        leftPadding: 18
        rightPadding: 18
        bottomPadding: 18
        background: Rectangle {
            id: r1
            color: Qt.lighter(item.backgroundColor, item.hovered ? 1.05 : 1)
            radius: 5
        }
    }
    Component {
        id: backup_notification
        NotificationItem {
            id: item
            backgroundColor: '#FF746C'
            contentItem: RowLayout {
                ColumnLayout {
                    RowLayout {
                        Image {
                            source: 'qrc:/000000/24/list-checks.svg'
                        }
                        Label {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            color: '#000000'
                            font.pixelSize: 13
                            font.weight: 700
                            text: 'Backup your wallet'
                            wrapMode: Label.WordWrap
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        color: '#000000'
                        font.pixelSize: 13
                        font.weight: 400
                        text: qsTrId('id_write_down_your_recovery_phrase')
                        wrapMode: Label.WordWrap
                    }
                }
                RightArrowIndicator {
                    active: true
                    black: true
                }
            }
            onClicked: stack_view.push(backup_page, { context: item.notification.context })
        }
    }
    Component {
        id: system_notification
        NotificationItem {
            AnalyticsView {
                active: true
                name: 'SystemMessage'
            }
            id: item
            backgroundColor: '#00BCFF'
            contentItem: RowLayout {
                spacing: 16
                    Image {
                    Layout.alignment: Qt.AlignCenter
                    source: 'qrc:/svg2/info_black.svg'
                }
                ColumnLayout {
                    spacing: 0
                    Label {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        clip: true
                        color: '#000'
                        font.pixelSize: 13
                        font.weight: 700
                        text: item.notification.network.displayName
                        wrapMode: Label.Wrap
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        clip: true
                        color: '#000'
                        font.pixelSize: 13
                        font.weight: 400
                        text: item.notification.message
                        textFormat: Label.MarkdownText
                        wrapMode: Label.Wrap
                        onLinkActivated: Qt.openUrlExternally(link)
                    }
                    RowLayout {
                        Layout.topMargin: 16
                        spacing: 0
                        visible: !item.notification.accepted
                        CheckBox {
                            Layout.alignment: Qt.AlignCenter
                            id: confirm_checkbox
                            Material.theme: Material.Light
                        }
                        Label {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            color: '#000'
                            text: qsTrId('id_i_confirm_i_have_read_and')
                            wrapMode: Label.Wrap
                        }
                        PrimaryButton {
                            Layout.alignment: Qt.AlignRight
                            Layout.leftMargin: 15
                            borderColor: '#000'
                            fillColor: 'transparent'
                            font.pixelSize: 14
                            enabled: confirm_checkbox.checked
                            font.capitalization: Font.Capitalize
                            text: qsTrId('id_accept').toLowerCase()
                            onClicked: item.notification.accept(controller.monitor)
                        }
                    }
                }
            }
        }
    }
    Component {
        id: outage_notification
        OutageNotificationView {
        }
    }

    Component {
        id: warning_notification
        WarningNotificationView {
        }
    }

    Component {
        id: two_factor_reset_notification
        TwoFactorResetNotificationView {
        }
    }
    Component {
        id: two_factor_expired_notification
        TwoFactorExpiredNotificationView {
        }
    }

    component OutageNotificationView: NotificationItem {
        id: view
        backgroundColor: '#9A0000'
        contentItem: RowLayout {
            spacing: 20
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/plugs_white'
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                color: '#FFFFFF'
                font.pixelSize: 13
                font.weight: 700
                text: 'Some accounts can not be logged in due to network issues. Please try again later.'
                wrapMode: Label.WordWrap
            }
            PrimaryButton {
                Layout.alignment: Qt.AlignCenter
                borderColor: '#FFFFFF'
                fillColor: '#FFFFFF'
                font.pixelSize: 12
                font.weight: 500
                text: 'Try again'
                textColor: '#1C1C1C'
                onClicked: {
                    stack_view.push(outage_page, {
                        context: self.context,
                        notification: view.notification,
                    })
                }
            }
        }
    }

    component WarningNotificationView: NotificationItem {
        id: warningView
        contentItem: ColumnLayout {
            spacing: 12
            RowLayout {
                spacing: 12
                Image {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    source: 'qrc:/svg2/warning-light.svg'
                }
                ColumnLayout {
                    spacing: 4
                    Label {
                        Layout.fillWidth: true
                        color: '#FFFFFF'
                        font.pixelSize: 16
                        font.weight: 600
                        text: warningView.notification.title
                        wrapMode: Label.WordWrap
                    }
                    Label {
                        Layout.fillWidth: true
                        color: '#FFFFFF'
                        font.pixelSize: 14
                        opacity: 0.8
                        text: warningView.notification.message
                        wrapMode: Label.WordWrap
                    }
                }
            }
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 10
                PrimaryButton {
                    text: 'Backup now'
                    borderColor: '#FFFFFF'
                    fillColor: '#FFFFFF'
                    textColor: '#000000'
                    onClicked: warningView.notification.trigger()
                }
                PrimaryButton {
                    text: 'Remind me later'
                    borderColor: '#FFFFFF'
                    fillColor: 'transparent'
                    textColor: '#FFFFFF'
                    onClicked: warningView.notification.dismiss()
                }
            }
        }
    }

    component TwoFactorResetNotificationView: NotificationItem {
        readonly property Session session: notification.context.getOrCreateSession(notification.network)
        id: view
        contentItem: ColumnLayout {
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

    component TwoFactorExpiredNotificationView: NotificationItem {
        id: view
        backgroundColor: '#F7D000'
        contentItem: RowLayout {
            spacing: 16
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/expired_2fa.svg'
            }
            ColumnLayout {
                spacing: 0
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    color: '#13151C'
                    font.pixelSize: 13
                    font.weight: 700
                    text: 'Update 2FA protection on some of your accounts'
                    wrapMode: Label.Wrap
                }
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    color: '#13151C'
                    font.pixelSize: 13
                    font.weight: 400
                    horizontalAlignment: Label.AlignJustify
                    text: 'Consider enabling 2FA on additional accounts where sensitive information is stored to enhance your overall security posture.'
                    wrapMode: Label.Wrap
                }
                RowLayout {
                    Layout.topMargin: 16
                    spacing: 40
                    HSpacer {
                    }
                    LinkButton {
                        text: qsTrId('id_learn_more')
                        textColor: '#13151C'
                        onClicked: Qt.openUrlExternally('https://help.blockstream.com/hc/en-us/articles/900001391763-How-does-Blockstream-Green-s-2FA-multisig-protection-work#h_01HRYKB9YRHWX02REXYY34VPV9')
                    }
                    PrimaryButton {
                        Layout.alignment: Qt.AlignCenter
                        borderColor: '#1C1C1C'
                        fillColor: '#1C1C1C'
                        font.pixelSize: 12
                        font.weight: 500
                        text: 'Re-enable 2FA'
                        textColor: '#FFFFFF'
                        onClicked: {
                            stack_view.push(two_factor_expired_page, {
                                context: self.context,
                                notification: view.notification,
                            })
                        }
                    }
                }
            }
        }
    }

    component UpdateNotificationView: NotificationItem {
        id: view
        backgroundColor: '#432004'
        contentItem: ColumnLayout {
            spacing: 12
            RowLayout {
                spacing: 12
                Image {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    source: 'qrc:/svg2/warning-light.svg'
                }
                ColumnLayout {
                    spacing: 4
                    Label {
                        Layout.fillWidth: true
                        color: '#FFFFFF'
                        font.pixelSize: 16
                        font.weight: 600
                        text: 'Update Available'
                        wrapMode: Label.WordWrap
                    }
                    Label {
                        Layout.fillWidth: true
                        color: '#FFFFFF'
                        font.pixelSize: 14
                        opacity: 0.8
                        text: view.notification.version
                              ? 'Version %1 is available. Please update to continue using the app.'
                                    .arg(view.notification.version)
                              : 'A new version is available. Please update to continue using the app.'
                        wrapMode: Label.WordWrap
                    }
                }
            }
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 10
                PrimaryButton {
                    text: 'Update'
                    borderColor: '#FFFFFF'
                    fillColor: '#FFFFFF'
                    textColor: '#000000'
                    onClicked: Qt.openUrlExternally('https://blockstream.com/app/')
                }
            }
        }
    }

    Component {
        id: outage_page
        OutagePage {
            id: page
            onLoadFinished: page.StackView.view.pop()
        }
    }
    Component {
        id: two_factor_expired_page
        TwoFactorExpiredSelectAccountPage {
            onCloseClicked: self.close()
        }
    }
}
