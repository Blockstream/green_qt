import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    signal deviceSelected(string deployment, JadeDevice device)
    required property string deployment
    id: self
    padding: 60
    rightItem: LinkButton {
        Layout.alignment: Qt.AlignCenter
        Layout.topMargin: 20
        text: qsTrId('id_setup_guide')
        onClicked: Qt.openUrlExternally('https://help.blockstream.com/hc/en-us/articles/19629901272345-Set-up-Jade')
    }
    footer: Pane {
        background: null
        padding: self.padding
        contentItem: ColumnLayout {
            BusyIndicator {
                Layout.alignment: Qt.AlignCenter
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.topMargin: 20
                color: '#FFF'
                font.family: 'SF Compact Display'
                font.pixelSize: 12
                font.weight: 600
                text: qsTrId('id_looking_for_device')
            }
            LinkButton {
                Layout.alignment: Qt.AlignCenter
                Layout.topMargin: 20
                text: qsTrId('id_troubleshoot')
                onClicked: Qt.openUrlExternally('https://help.blockstream.com/hc/en-us/articles/900005443223-Fix-issues-connecting-Jade-via-USB')
            }
        }
    }
    contentItem: ColumnLayout {
        spacing: 0
        VSpacer {
        }
        Timer {
            id: change_timer
            interval: 3000
            repeat: true
            running: true
            onTriggered: swipe_view.currentIndex = (swipe_view.currentIndex + 1) % swipe_view.count
        }
        Repeater {
            id: device_repeater
            model: DeviceListModel {
                type: Device.BlockstreamJade
            }
            delegate: DeviceDelegate {
            }
        }
        SwipeView {
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: 400
            Layout.preferredHeight: 400
            Keys.onLeftPressed: swipe_view.currentIndex = (swipe_view.currentIndex - 1 + swipe_view.count) % swipe_view.count
            Keys.onRightPressed: swipe_view.currentIndex = (swipe_view.currentIndex + 1) % swipe_view.count
            id: swipe_view
            clip: true
            focus: true
            visible: device_repeater.count === 0
            onCurrentIndexChanged: change_timer.restart()
            StepPane {
                step: 1
                image: 'qrc:/png/connect_jade_1.png'
                title: qsTrId('id_power_on_jade')
                text: qsTrId('id_hold_the_green_button_on_the')
            }
            StepPane {
                step: 2
                image: 'qrc:/png/connect_jade_2.png'
                title: qsTrId('id_follow_the_instructions_on_jade')
                text: qsTrId('id_select_initalize_to_create_a')
            }
            StepPane {
                step: 2
                image: 'qrc:/png/connect_jade_3.png'
                title: qsTrId('id_connect_using_usb_or_bluetooth')
                text: qsTrId('id_choose_a_usb_or_bluetooth')
            }
        }
        PageIndicator {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 20
            count: swipe_view.count
            currentIndex: swipe_view.currentIndex
            interactive: false
            visible: device_repeater.count === 0
        }
        VSpacer {
        }
    }

    component StepPane: ColumnLayout {
        required property int step
        required property string image
        required property string title
        required property string text
        id: step_pane
        focus: false
        VSpacer {
        }
        Image {
            Layout.alignment: Qt.AlignCenter
            source: step_pane.image
        }
        Pane {
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: 325
            background: Rectangle {
                radius: 4
                color: '#222226'
            }
            padding: 20
            contentItem: ColumnLayout {
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    color: '#00B45A'
                    font.family: 'SF Compact Display'
                    font.pixelSize: 12
                    font.weight: 700
                    horizontalAlignment: Label.AlignHCenter
                    text: [qsTrId('id_step'), step_pane.step].join(' ')
                    wrapMode: Label.WordWrap
                }
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    color: '#FFFFFF'
                    font.family: 'SF Compact Display'
                    font.pixelSize: 14
                    font.weight: 600
                    horizontalAlignment: Label.AlignHCenter
                    text: step_pane.title
                    wrapMode: Label.WordWrap
                }
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    color: '#9C9C9C'
                    font.family: 'SF Compact Display'
                    font.pixelSize: 12
                    font.weight: 400
                    horizontalAlignment: Label.AlignHCenter
                    text: step_pane.text
                    wrapMode: Label.WordWrap
                }
            }
        }
    }

    component DeviceDelegate: AbstractButton {
        required property JadeDevice device
        Layout.minimumWidth: 325
        Layout.alignment: Qt.AlignCenter
        id: delegate
        padding: 20
        background: Rectangle {
            color: '#222226'
            radius: 5
            Rectangle {
                border.width: 2
                border.color: '#00B45A'
                color: 'transparent'
                radius: 9
                anchors.fill: parent
                anchors.margins: -4
                visible: delegate.visualFocus
            }
        }
        contentItem: RowLayout {
            spacing: 8
            Label {
                Layout.fillWidth: true
                font.family: 'SF Compact Display'
                font.pixelSize: 16
                font.weight: 700
                text: delegate.device.name
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/next_arrow.svg'
            }
        }
        onClicked: self.deviceSelected(self.deployment, delegate.device)
    }
}
