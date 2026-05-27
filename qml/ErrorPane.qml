import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

Collapsible {
    required property var error
    property var _error
    Layout.fillWidth: true
    id: self
    animationVelocity: 300
    collapsed: true
    z: -1
    onErrorChanged: {
        if (self.error) {
            self._error = self.error
            timer.restart()
        } else {
            self.collapsed = true
            timer.stop()
        }
    }
    Timer {
        id: timer
        interval: self.animationVelocity * 2
        repeat: false
        running: false
        onTriggered: self.collapsed = false
    }
    Pane {
        id: pane
        leftPadding: 10
        rightPadding: 10
        bottomPadding: 15
        topPadding: self.Layout.topMargin !== 0 ? 25 : 15
        width: self.width
        background: Rectangle {
            color: '#3B080F'
            radius: 5
        }
        contentItem: RowLayout {
            spacing: 10
            Image {
                source: 'qrc:/svg2/info_red.svg'
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                font.pixelSize: 12
                font.weight: 600
                color: '#C91D36'
                text: UtilJS.formatError(self._error ?? '')
                wrapMode: Label.Wrap
            }
        }
    }
}
