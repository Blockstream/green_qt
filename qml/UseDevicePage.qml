import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    signal connectJadeClicked()
    signal connectLedgerClicked()
    StackView.onActivated: Analytics.recordEvent('wallet_hww')
    id: self
    footer: null
    padding: 60
    Timer {
        id: change_timer
        interval: 3000
        repeat: true
        running: true
        onTriggered: swipe_view.currentIndex = (swipe_view.currentIndex + 1) % swipe_view.count
    }
    SwipeView {
        Layout.alignment: Qt.AlignCenter
        Layout.preferredWidth: 450
        Layout.preferredHeight: 350
        id: swipe_view
        clip: true
        onCurrentIndexChanged: change_timer.restart()
        ColumnLayout {
            VSpacer {
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                Layout.preferredHeight: 240
                antialiasing: true
                fillMode: Image.PreserveAspectFit
                mipmap: true
                smooth: true
                source: 'qrc:/svg3/Authenticator-2.svg'
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
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
                Layout.topMargin: 10
                color: '#FFF'
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
            Image {
                Layout.alignment: Qt.AlignCenter
                Layout.preferredHeight: 240
                antialiasing: true
                fillMode: Image.PreserveAspectFit
                mipmap: true
                smooth: true
                source: 'qrc:/svg3/Chip.svg'
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
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
                Layout.topMargin: 10
                color: '#FFF'
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
            Image {
                Layout.alignment: Qt.AlignCenter
                Layout.preferredHeight: 240
                antialiasing: true
                fillMode: Image.PreserveAspectFit
                mipmap: true
                smooth: true
                source: 'qrc:/svg3/Globe.svg'
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
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
                Layout.topMargin: 10
                color: '#FFF'
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
        Layout.minimumWidth: 360
        Layout.topMargin: 20
        font.weight: 500
        text: qsTrId('id_connect_jade')
        onClicked: self.connectJadeClicked()
    }
    RegularButton {
        Layout.alignment: Qt.AlignCenter
        Layout.minimumWidth: 360
        Layout.topMargin: 20
        font.weight: 500
        cyan: true
        text: qsTrId('id_connect_a_different_hardware')
        onClicked: self.connectLedgerClicked()
    }
    LinkButton {
        Layout.alignment: Qt.AlignCenter
        Layout.topMargin: 20
        font.underline: true
        text: qsTrId('id_dont_have_a_jade_check_our_store')
        external: true
        onClicked: Qt.openUrlExternally('https://store.blockstream.com/')
    }
}
