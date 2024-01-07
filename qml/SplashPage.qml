import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

MainPage {
    signal timeout()
    Timer {
        running: true
        interval: 1500
        onTriggered: self.timeout()
    }
    id: self
    padding: 60
    contentItem: ColumnLayout {
        spacing: 10
        VSpacer {
        }
        Image {
            Layout.alignment: Qt.AlignCenter
            Layout.minimumHeight: 183
            Layout.minimumWidth: 558
            Layout.bottomMargin: 60
            id: image
            sourceSize.height: 183
            sourceSize.width: 558
            source: 'qrc:/svg/green_logo.svg'
            layer.enabled: true
            layer.effect: MultiEffect {
                autoPaddingEnabled: true
                blurEnabled: true
                blurMax: 64
                NumberAnimation on blur {
                    easing.type: Easing.OutCubic
                    from: 1
                    to: 0
                    duration: 300
                }
            }
            NumberAnimation on scale {
                easing.type: Easing.OutCubic
                from: 0.9
                to: 0.8
                duration: 300
            }
            NumberAnimation on opacity {
                easing.type: Easing.OutCubic
                from: 0
                to: 1
                duration: 300
            }
        }
        VSpacer {
        }
        Image {
            Layout.alignment: Qt.AlignCenter
            source: 'qrc:/svg/blockstream-logo.svg'
            opacity: 0
            SequentialAnimation on opacity {
                PauseAnimation {
                    duration: 500
                }
                NumberAnimation {
                    easing.type: Easing.InOutSine
                    to: 0.3
                    duration: 1000
                }
            }
        }
    }
}
