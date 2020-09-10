import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Controls 2.13

Label {
    MouseArea {
        ToolTip.text: qsTrId('id_click_to_copy')
        ToolTip.delay: 500
        ToolTip.visible: containsMouse
        hoverEnabled: true
        anchors.fill: parent
        onClicked: {
            Clipboard.copy(parent.text)
            ToolTip.show(qsTrId('id_copied_to_clipboard'), 1000)
        }
    }
}
