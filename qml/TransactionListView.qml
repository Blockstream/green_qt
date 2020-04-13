import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

ListView {
    clip: true
    spacing: 8

    model: account.transactions

    Component {
        id: bump_fee_dialog
        BumpFeeDialog {  }
    }

    delegate: TransactionDelegate {
        width: parent.width
        transaction: modelData
        onClicked: stack_view.push(transaction_view_component, { transaction })
    }

    ScrollBar.vertical: ScrollBar { }

    ScrollShadow {}
}
