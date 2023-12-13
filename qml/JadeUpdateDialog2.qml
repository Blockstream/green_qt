import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

WalletDialog {
    required property JadeDevice device
    id: self
    clip: true
    width: 650
    height: 700
    contentItem: GStackView {
        id: stack_view
        initialItem: JadeAdvancedUpdateView {
            device: self.device
            showSkip: false
            onFirmwareSelected: (firmware) => stack_view.push(confirm_update_view, { firmware })
        }
    }
    Component {
        id: confirm_update_view
        JadeConfirmUpdatePage {
            id: view
            device: self.device
            onUpdateFailed: stack_view.pop()
            onUpdateFinished: stack_view.replace(completed_view)
        }
    }
    Component {
        id: completed_view
        ColumnLayout {
            VSpacer {
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/png/completed.png'
            }
            VSpacer {
            }
            Item {
                Layout.alignment: Qt.AlignCenter
                Layout.bottomMargin: 60
                Layout.minimumWidth: 400
                Layout.minimumHeight: 4
                Rectangle {
                    anchors.centerIn: parent
                    implicitHeight: 2
                    radius: 1
                    color: '#00B45A'
                    NumberAnimation on implicitWidth {
                        easing.type: Easing.OutCubic
                        from: 300
                        to: 0
                        duration: 2000
                        onFinished: stack_view.pop()
                    }
                    opacity: Math.min(1, implicitWidth / 20)
                }
            }
        }
    }
}
