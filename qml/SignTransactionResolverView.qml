import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

Column {
    property SignTransactionResolver resolver
    property var actions: resolver.failed ? failed_action : null

    spacing: 16

    Action {
        id: failed_action
        text: qsTrId('id_cancel')
        onTriggered: controller_dialog.accept()
    }
    StackView {
        id: stack_view
        implicitHeight: currentItem.implicitHeight
        implicitWidth: currentItem.implicitWidth
        initialItem: BusyIndicator {}
    }
}
