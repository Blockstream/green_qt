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
        popup.visible = hovered
    }
    Connections {
        target: self.activity.progress
        function onValueChanged(value) {
            if (value > 0) {
                popup.visible = true
            }
        }
    }
    Connections {
        target: self.activity
        function onStatusChanged(status) {
            if (self.activity.status === Activity.Finished) {
                popup.visible = false
            }
        }
    }
    Popup {
        id: popup
        y: -height - 12
        visible: false
        closePolicy: Popup.NoAutoClose
        background: Rectangle {
            color: constants.c400
            radius: 4
            opacity: 0.9
        }
        contentItem: RowLayout {
            Label {
                text: 'TOR'
            }
            ProgressBar {
                RowLayout.maximumWidth: 64
                visible: self.pending
                from: self.activity.progress.from
                to: self.activity.progress.to
                value: self.activity.progress.value
                indeterminate: self.activity.progress.indeterminate
                Behavior on value {
                    SmoothedAnimation { }
                }
            }
            Label {
                visible: self.pending
                text: self.activity.logs[0] || 'Initializing'
            }
        }
    }
    BlinkAnimation on opacity {
        running: activity.status === Activity.Pending
    }
}
