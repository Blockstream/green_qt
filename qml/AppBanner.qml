import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Collapsible {
    AppUpdateController {
        id: controller
    }
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

    readonly property var notifications: {
        const notifications = []
        if (controller.notification) {
            notifications.push(controller.notification)
        }
        return notifications
    }

    SwipeView {
        id: stack_layout
        clip: true
        orientation: Qt.Vertical
        interactive: false
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        currentIndex: {
            for (let i = self.notifications.length - 1; i >= 0; i--) {
                if (!self.notifications[i].dismissed) {
                    return i
                }
            }
            return 0
        }

        x: 20
        width: self.width - 40
        implicitHeight: 108
        Repeater {
            model: self.notifications
            delegate: Loader {
                readonly property Notification notification: loader.modelData
                required property var modelData
                id: loader
                sourceComponent: {
                    if (loader.notification instanceof UpdateNotification) {
                        return update_banner
                    }
                }
            }
        }
    }

    Component {
        id: banner
        Banner {
        }
    }

    component Banner: Pane {
        property bool dismissed
        leftPadding: 20
        rightPadding: 20
        topPadding: 40
        bottomPadding: 20
    }

    Component {
        id: update_banner
        Banner {
            id: banner
            background: Rectangle {
                color: '#00B45A'
                radius: 8
            }
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
                CloseButton {
                    Layout.alignment: Qt.AlignCenter
                    visible: notification.dismissable
                    onClicked: notification.dismiss()
                }
            }
        }
    }
}
