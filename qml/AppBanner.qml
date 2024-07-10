import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

Collapsible {
    required property var notifications

    id: self
    collapsed: {
        for (let i = 0; i < self.notifications.length; i++) {
            const notification = self.notifications[i]
            if (!self.notifications[i].dismissed) return false
        }
        return true
    }
    contentWidth: self.width
    contentHeight: stack_layout.height - 20
    animationVelocity: 200


    SwipeView {
        id: stack_layout
        clip: true
        spacing: 8
        orientation: Qt.Vertical
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        x: 20
        width: self.width - 40
        implicitHeight: 108
        Repeater {
            model: self.notifications
            delegate: Loader {
                readonly property Notification _notification: loader.modelData
                required property var modelData
                id: loader
                sourceComponent: {
                    const notification = loader._notification
                    if (notification instanceof UpdateNotification) {
                        return update_banner
                    } else if (notification instanceof OutageNotification) {
                        return outage_banner
                    } else if (notification instanceof TwoFactorExpiredNotification) {
                        return two_factor_expired_banner
                    } else if (notification instanceof SystemNotification) {
                        return system_message_banner
                    } else if (notification instanceof AnalyticsAlertNotification) {
                        return analytics_alert_banner
                    }
                }
            }
        }
    }

    ColumnLayout {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        visible: self.notifications.length > 1
        x: self.width - 14
        Repeater {
            model: self.notifications
            delegate: Rectangle {
                color: '#fff'
                opacity: index === stack_layout.currentIndex ? 1 : 0.6
                radius: 2
                implicitHeight: 4
                implicitWidth: 4
            }
        }
    }

    Component {
        id: outage_banner
        OutageBanner {
        }
    }
    Component {
        id: two_factor_expired_banner
        TwoFactorExpiredBanner {
        }
    }
    Component {
        id: banner
        Banner {
        }
    }

    component Banner: Pane {
        property Notification notification: _notification
        property color backgroundColor
        id: banner
        leftPadding: 20
        rightPadding: 20
        topPadding: 40
        bottomPadding: 20
        background: Rectangle {
            color: banner.backgroundColor
            radius: 8
        }
    }
    component OutageBanner: Banner {
        id: banner
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
                onClicked: banner.notification.trigger()
            }
        }
    }
    component TwoFactorExpiredBanner: Banner {
        id: banner
        backgroundColor: '#F7D000'
        contentItem: RowLayout {
            spacing: 20
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/expired_2fa.svg'
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                color: '#070B0E'
                font.pixelSize: 13
                font.weight: 700
                text: 'Some coins are no longer 2FA protected (%1 accounts)'.arg(banner.notification.accounts.length)
                wrapMode: Label.WordWrap
            }
            PrimaryButton {
                Layout.alignment: Qt.AlignCenter
                borderColor: '#1C1C1C'
                fillColor: '#1C1C1C'
                font.pixelSize: 12
                font.weight: 500
                text: 'Re-enable 2FA'
                textColor: '#FFFFFF'
                onClicked: banner.notification.trigger()
            }
            CloseButton {
                Layout.alignment: Qt.AlignCenter
                black: true
                onClicked: banner.notification.dismiss()
            }
        }
    }
    Component {
        id: system_message_banner
        Banner {
            id: banner
            backgroundColor: '#00B45A'
            contentItem: RowLayout {
                spacing: 20
                Image {
                    Layout.alignment: Qt.AlignCenter
                    source: 'qrc:/svg2/info_white.svg'
                }
                Label {
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    color: '#FFFFFF'
                    font.pixelSize: 13
                    font.weight: 700
                    text: banner.notification.message
                    wrapMode: Label.WordWrap
                }
                PrimaryButton {
                    Layout.alignment: Qt.AlignCenter
                    borderColor: '#FFFFFF'
                    fillColor: '#FFFFFF'
                    font.pixelSize: 12
                    font.weight: 500
                    text: qsTrId('id_accept')
                    textColor: '#1C1C1C'
                    onClicked: banner.notification.trigger()
                }
                CloseButton {
                    Layout.alignment: Qt.AlignCenter
                    onClicked: banner.notification.dismiss()
                }
            }
        }
    }
    Component {
        id: analytics_alert_banner
        Banner {
            id: banner
            backgroundColor: '#00B45A'
            contentItem: RowLayout {
                spacing: 20
                Image {
                    Layout.alignment: Qt.AlignCenter
                    source: 'qrc:/svg2/warning_white.svg'
                }
                ColumnLayout {
                    Label {
                        Layout.alignment: Qt.AlignCenter
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        color: '#FFFFFF'
                        font.pixelSize: 13
                        font.weight: 700
                        text: notification.alert.title
                        wrapMode: Label.WordWrap
                    }
                    Label {
                        Layout.alignment: Qt.AlignCenter
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        color: '#FFFFFF'
                        font.pixelSize: 13
                        font.weight: 400
                        opacity: 0.75
                        text: notification.alert.message
                        wrapMode: Label.WordWrap
                    }
                }
                LinkButton {
                    font.bold: true
                    font.pixelSize: 14
                    text: qsTrId('id_learn_more')
                    textColor: '#FFFFFF'
                    onClicked: Qt.openUrlExternally(notification.alert.link)
                }
                CloseButton {
                    Layout.alignment: Qt.AlignCenter
                    visible: notification.dismissable
                    onClicked: notification.dismiss()
                }
            }
        }
    }

    Component {
        id: update_banner
        Banner {
            id: banner
            backgroundColor: '#00B45A'
            contentItem: RowLayout {
                spacing: 20
                Image {
                    Layout.alignment: Qt.AlignCenter
                    source: 'qrc:/svg2/star_white.svg'
                }
                Label {
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    color: '#FFFFFF'
                    font.pixelSize: 13
                    font.weight: 700
                    text: qsTrId('There is a newer version of Green Desktop available')
                    wrapMode: Label.WordWrap
                }
                PrimaryButton {
                    Layout.alignment: Qt.AlignCenter
                    borderColor: '#FFFFFF'
                    fillColor: '#FFFFFF'
                    font.pixelSize: 12
                    font.weight: 500
                    text: qsTrId('Download %1').arg(notification.version)
                    textColor: '#1C1C1C'
                    onClicked: Qt.openUrlExternally('https://blockstream.com/green/')
                }
            }
        }
    }
}
