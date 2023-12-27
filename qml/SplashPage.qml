import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

MainPage {
    signal timeout()
    Timer {
        running: true
        interval: 400
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
            sourceSize.height: 183
            sourceSize.width: 558
            source: 'qrc:/svg/green_logo.svg'
            NumberAnimation on scale {
                easing.type: Easing.OutCubic
                from: 1
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
        Label {
            Layout.alignment: Qt.AlignCenter
            font.pixelSize: 12
            opacity: 0.4
            text: Qt.application.version
        }
    }
}
