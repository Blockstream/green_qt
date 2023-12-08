import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Pane {
    Layout.alignment: Qt.AlignCenter
    Timer {
        id: change_timer
        interval: 3000
        repeat: true
        running: true
        onTriggered: swipe_view.currentIndex = (swipe_view.currentIndex + 1) % swipe_view.count
    }
    background: null
    padding: 0
    contentItem: ColumnLayout {
        SwipeView {
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: 400
            Layout.preferredHeight: 400
            Keys.onLeftPressed: swipe_view.currentIndex = (swipe_view.currentIndex - 1 + swipe_view.count) % swipe_view.count
            Keys.onRightPressed: swipe_view.currentIndex = (swipe_view.currentIndex + 1) % swipe_view.count
            id: swipe_view
            clip: true
            focus: true
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
                step: 3
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
                    font.pixelSize: 12
                    font.weight: 400
                    horizontalAlignment: Label.AlignHCenter
                    text: step_pane.text
                    wrapMode: Label.WordWrap
                }
            }
        }
    }
}
