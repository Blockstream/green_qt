import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Controls 2.13

Label {
    property real delay: 500
    id: self
    background: MouseArea {
        ToolTip.text: qsTrId('id_click_to_copy')
        ToolTip.delay: self.delay
        ToolTip.visible: containsMouse
        hoverEnabled: true
        onClicked: {
            Clipboard.copy(parent.text)
            ToolTip.show(qsTrId('id_copied_to_clipboard'), 1000)
        }
    }
}
