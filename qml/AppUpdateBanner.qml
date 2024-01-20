import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Collapsible {
    readonly property url url: 'https://blockstream.com/green/'
    function dismiss() {
        self.collapsed = true
    }
    AppUpdateController {
        id: controller
        Component.onCompleted: checkForUpdates()
    }
    id: self
    collapsed: !controller.updateAvailable
    contentWidth: self.width
    contentHeight: button.height - 20
    animationVelocity: 100
    AbstractButton {
        id: button
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        leftPadding: 20
        rightPadding: 20
        topPadding: 40
        bottomPadding: 20
        x: 20
        width: self.width - 40
        background: Rectangle {
            color: button.hovered ? '#00DD6E' : '#00B45A'
            radius: 8
        }
        contentItem: RowLayout {
            spacing: 20
            CloseButton {
                onClicked: self.dismiss()
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                color: '#FFF'
                font.pixelSize: 16
                font.weight: 600
                text: qsTrId('There is a newer version of Green Desktop available')
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                color: '#FFF'
                font.pixelSize: 16
                font.weight: 800
                text: qsTrId('Download %1').arg(controller.latestVersion)
            }
            ShareButton {
                Layout.alignment: Qt.AlignCenter
                url: self.url
            }
        }
        onClicked: Qt.openUrlExternally(self.url)
    }
}
