import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Window

import "jade.js" as JadeJS

Dialog {
    signal setupClicked(JadeDevice device)
    required property JadeDevice device
    Connections {
        target: self.device
        function onConnectedChanged() {
            self.close()
        }
    }
    Overlay.modal: MultiEffect {
        anchors.fill: parent
        autoPaddingEnabled: false
        brightness: self.visible ? -0.05 : 0
        Behavior on brightness {
            NumberAnimation { duration: 200 }
        }
        blurEnabled: true
        blurMax: 64
        blur: self.visible ? 1 : 0
        Behavior on blur {
            NumberAnimation { duration: 200 }
        }
        source: ApplicationWindow.contentItem
    }
    id: self
    objectName: "JadeNotificationDialog"
    anchors.centerIn: parent
    closePolicy: Dialog.NoAutoClose
    topPadding: 60
    bottomPadding: 60
    leftPadding: 60
    rightPadding: 60
    visible: self.device.connected
    background: Rectangle {
        color: '#181818'
        radius: 10
        border.width: 1
        border.color: Qt.alpha('#FFFFFF', 0.07)
    }
    contentItem: ColumnLayout {
        spacing: 20
        Label {
            Layout.alignment: Qt.AlignCenter
            font.pixelSize: 26
            font.weight: 600
            text: 'Hardware Wallet Connected'
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            font.pixelSize: 14
            font.weight: 600
            opacity: 0.4
            text: 'A new device has been detected, please set it up to start using it.'
        }
        MultiImage {
            Layout.alignment: Qt.AlignCenter
            Layout.preferredHeight: 260
            Layout.preferredWidth: 320
            foreground: JadeJS.image(self.device, 0)
            margins: 30
        }
        PrimaryButton {
            Layout.alignment: Qt.AlignCenter
            Layout.minimumWidth: 325
            text: 'Set up Jade'
            onClicked: self.setupClicked(self.device)
        }
        LinkButton {
            Layout.alignment: Qt.AlignCenter
            text: qsTrId('id_not_now')
            onClicked: self.close()
        }
    }
}
