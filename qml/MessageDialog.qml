import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

WalletDialog {
    property alias message: message_label.text
    property bool shouldOpen: false
    property list<Action> actions
    id: self
    closePolicy: Popup.NoAutoClose
    contentItem: Label {
        id: message_label
        padding: 0
        wrapMode: Text.Wrap
    }
    footer: DialogFooter {
        HSpacer {}
        Repeater {
            model: self.actions
            GButton {
                destructive: modelData.destructive || false
                highlighted: modelData.highlighted || false
                large: true
                action: modelData
            }
        }
    }
}
