import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Controls 2.13

Label {
    property real delay: 500
    id: self
//    padding: 4
//    rightPadding: 24
    background: MouseArea {
        id: mouse_area
        hoverEnabled: true
        onClicked: {
            Clipboard.copy(self.text)
            ToolTip.show(qsTrId('id_copied_to_clipboard'), 1000)
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: -8
            anchors.rightMargin: -32
            color: Qt.rgba(0, 0, 0, mouse_area.containsMouse ? 0.2 : 0)
            radius: 4
            Image {
                anchors.right: parent.right
                anchors.margins: 4
                anchors.verticalCenter: parent.verticalCenter
                sourceSize.width: 16
                sourceSize.height: 16
                source: 'qrc:/svg/copy.svg'
                visible: mouse_area.containsMouse ? 1 : 0
            }
        }
    }
    ToolTip.text: qsTrId('id_click_to_copy')
    ToolTip.delay: self.delay
    ToolTip.visible: mouse_area.containsMouse
}
