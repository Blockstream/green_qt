import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    signal connectJadeClicked()
    signal connectLedgerClicked()
    id: self
    padding: 60
    footerItem: ColumnLayout {
        LinkButton {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 20
            text: 'Don’t have a Jade? Check our store'
            onClicked: Qt.openUrlExternally('https://store.blockstream.com/')
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
        SwipeView {
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: 400
            Layout.preferredHeight: 400
            id: swipe_view
            clip: true
            onCurrentIndexChanged: change_timer.restart()
            ColumnLayout {
                VSpacer {
                }
                MultiImage {
                    Layout.alignment: Qt.AlignCenter
                    foreground: 'qrc:/png/jade_0.png'
                    width: 352
                    height: 240
                }
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    Layout.topMargin: 20
                    color: '#FFF'
                    font.pixelSize: 26
                    font.weight: 600
                    horizontalAlignment: Label.AlignHCenter
                    text: qsTrId('id_welcome_to_blockstream_jade')
                    wrapMode: Label.WordWrap
                }
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    Layout.topMargin: 20
                    color: '#9C9C9C'
                    font.pixelSize: 14
                    font.weight: 400
                    horizontalAlignment: Label.AlignHCenter
                    wrapMode: Label.WordWrap
                    text: qsTrId('id_jade_is_a_specialized_device')
                }
            }
            ColumnLayout {
                VSpacer {
                }
                MultiImage {
                    Layout.alignment: Qt.AlignCenter
                    foreground: 'qrc:/png/onboarding_cpu.png'
                    width: 352
                    height: 240
                }
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    Layout.topMargin: 20
                    color: '#FFF'
                    font.pixelSize: 26
                    font.weight: 600
                    horizontalAlignment: Label.AlignHCenter
                    text: qsTrId('id_hardware_security')
                    wrapMode: Label.WordWrap
                }
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    Layout.topMargin: 20
                    color: '#9C9C9C'
                    font.pixelSize: 14
                    font.weight: 400
                    horizontalAlignment: Label.AlignHCenter
                    wrapMode: Label.WordWrap
                    text: qsTrId('id_your_bitcoin_and_liquid_assets')
                }
            }
            ColumnLayout {
                VSpacer {
                }
                MultiImage {
                    Layout.alignment: Qt.AlignCenter
                    foreground: 'qrc:/png/onboarding_globe.png'
                    width: 352
                    height: 240
                }
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    Layout.topMargin: 20
                    color: '#FFF'
                    font.pixelSize: 26
                    font.weight: 600
                    horizontalAlignment: Label.AlignHCenter
                    text: qsTrId('id_offline_key_storage')
                    wrapMode: Label.WordWrap
                }
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    Layout.topMargin: 20
                    color: '#9C9C9C'
                    font.pixelSize: 14
                    font.weight: 400
                    horizontalAlignment: Label.AlignHCenter
                    wrapMode: Label.WordWrap
                    text: qsTrId('id_jade_is_an_isolated_device_not')
                }
            }
        }
        PageIndicator {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 20
            count: swipe_view.count
            currentIndex: swipe_view.currentIndex
            interactive: false
        }
        PrimaryButton {
            Layout.alignment: Qt.AlignCenter
            Layout.minimumWidth: 400
            Layout.topMargin: 20
            text: qsTrId('id_connect_jade')
            onClicked: self.connectJadeClicked()
        }
        RegularButton {
            Layout.alignment: Qt.AlignCenter
            Layout.minimumWidth: 400
            Layout.topMargin: 10
            text: qsTrId('id_connect_a_different_hardware')
            onClicked: self.connectLedgerClicked()
        }
        VSpacer {
        }
    }
}
