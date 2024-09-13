import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Collapsible {
    readonly property bool show: Settings.useTor && !Settings.useProxy && SessionManager.tor?.progress >= 0
    property bool dismissed: false
    onShowChanged: self.dismissed = false
    id: self
    animationVelocity: 200
    contentWidth: self.width
    contentHeight: pane.height
    collapsed: !self.show || self.dismissed
    Pane {
        id: pane
        leftPadding: 20
        rightPadding: 20
        topPadding: 10
        bottomPadding: 10
        x: 25
        width: self.width - 50
        background: Rectangle {
            color: '#7D4698'
            radius: 8
        }
        contentItem: RowLayout {
            spacing: 20
            Image {
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                source: 'qrc:/svg/torV2.svg'
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                font.pixelSize: 12
                font.weight: 600
                text: SessionManager.tor?.tag === 'done' ? qsTrId('id_tor_is_connected') : qsTrId('id_tor_status')
            }
            HSpacer {
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                id: tor_summary_text
                font.pixelSize: 12
                font.weight: 600
                text: SessionManager.tor?.summary ?? ''
                visible: tor_summary_text.text !== '' && tor_progress_bar.value < 100
            }
            TProgressBar {
                Layout.alignment: Qt.AlignCenter
                Layout.minimumWidth: 200
                id: tor_progress_bar
                from: 0
                to: 100
                value: SessionManager.tor?.progress ?? 0
                visible: tor_progress_bar.value < 100
                Behavior on value {
                    SmoothedAnimation {
                        velocity: 40
                    }
                }
            }
            CloseButton {
                onClicked: self.dismissed = true
            }
        }
    }
}
