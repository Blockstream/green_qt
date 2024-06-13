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
