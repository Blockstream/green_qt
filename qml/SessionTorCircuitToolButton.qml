import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

ToolButton {
    required property SessionTorCircuitActivity activity
    property bool pending: true
    id: self
    flat: true
    icon.source: 'qrc:/svg/torV2.svg'
    onHoveredChanged: {
        if (hovered) pending = activity.status === Activity.Pending
    }
    onActivityChanged: if (!activity) self.destroy()
    BlinkAnimation on opacity {
        running: activity.status === Activity.Pending
    }
}
