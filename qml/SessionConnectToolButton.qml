import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

ToolButton {
    required property SessionConnectActivity activity
    id: self
    flat: true
    icon.source: 'qrc:/svg/green_server.svg'
    onActivityChanged: if (!activity) self.destroy()
    Popup {
        id: popup
        y: -height - 12
        visible: self.hovered
        closePolicy: Popup.NoAutoClose
        background: Rectangle {
            color: constants.c400
            radius: 4
            opacity: 0.9
        }
        contentItem: RowLayout {
            Label {
                text: self.activity.status === Activity.Pending ? 'Connecting' : 'Connected'
            }
        }
    }
    BlinkAnimation on opacity {
        running: activity.status === Activity.Pending
    }
}
