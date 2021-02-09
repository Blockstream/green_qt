import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

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
