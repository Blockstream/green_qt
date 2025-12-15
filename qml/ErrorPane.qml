import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Collapsible {
    required property var error
    Layout.fillWidth: true
    id: self
    animationVelocity: 300
    contentWidth: self.width
    contentHeight: pane.height
    collapsed: !self.error
    z: -1
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
                text: self.error && self.error.startsWith('id_') ? qsTrId(self.error) : (self.error ?? '')
                wrapMode: Label.Wrap
            }
        }
    }
}
