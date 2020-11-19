import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5

ListView {
    id: list_view
    required property Account account
    signal clicked(Transaction transaction)
    clip: true

    model: TransactionListModel {
        account: list_view.account
    }

    delegate: TransactionDelegate {
        hoverEnabled: false
        width: list_view.width
        onClicked: list_view.clicked(transaction)
    }

    ScrollBar.vertical: ScrollBar { }

    Component {
        id: transaction_view_component
        TransactionView { }
    }

    BusyIndicator {
        width: 32
        height: 32
        opacity: running ? 1 : 0
        Behavior on opacity { OpacityAnimator {} }
        running: model.fetching
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.margins: 8
    }
}
