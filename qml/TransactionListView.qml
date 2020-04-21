import QtQuick 2.12
import QtQuick.Controls 2.5

ListView {
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
