import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5

ListView {
    property Account account
    clip: true
    model: account.transactions
    delegate: TransactionDelegate {
        width: parent.width
        transaction: modelData
        onClicked: stack_view.push(transaction_view_component, { transaction })
    }
    ScrollBar.vertical: ScrollBar { }
    ScrollShadow {}
}
