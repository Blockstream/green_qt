import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Controls 2.13

Label {
    property real delay: 500
    property string copyText: text
    id: self
    background: MouseArea {
        id: mouse_area
        hoverEnabled: true
        onClicked: {
            Clipboard.copy(self.copyText)
            ToolTip.show(qsTrId('id_copied_to_clipboard'), 1000)
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            color: Qt.rgba(0, 0, 0, mouse_area.containsMouse ? 0.2 : 0)
            radius: 4
        }
    }
    ToolTip.text: qsTrId('id_click_to_copy')
    ToolTip.delay: self.delay
    ToolTip.visible: mouse_area.containsMouse
}
