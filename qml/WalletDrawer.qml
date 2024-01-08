import Blockstream.Green
import QtQuick

AbstractDrawer {
    required property Context context

    closePolicy: AbstractDrawer.CloseOnEscape
    onClosed: self.destroy()

    Connections {
        target: self.context
        function onAutoLogout() {
            self.close()
        }
    }

    id: self
    edge: Qt.RightEdge
}
