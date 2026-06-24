import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls

Label {
    signal copyClicked()
    property string copyText: self.text

    id: self
    rightPadding: collapsible.width

    Collapsible {
        id: collapsible
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        animationVelocity: 500
        collapsed: !hover_handler.hovered && !timer.running
        horizontalCollapse: true
        verticalCollapse: false
        Image {
            x: 8
            source: timer.running ? 'qrc:/svg2/check.svg' : 'qrc:/svg2/copy.svg'
        }
    }

    HoverHandler {
        id: hover_handler
    }

    TapHandler {
        onTapped: {
            Clipboard.copy(self.copyText)
            self.copyClicked()
            timer.restart()
        }
    }

    Timer {
        id: timer
        repeat: false
        interval: 1000
    }
}
