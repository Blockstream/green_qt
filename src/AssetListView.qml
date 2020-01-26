import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

ListView {
    id: list_view
    signal clicked(Balance balance)

    model: account.balances
    spacing: 8

    delegate: AssetDelegate {
        balance: modelData
        width: parent.width
        onClicked: if (hasDetails) list_view.clicked(balance)
    }

    ScrollBar.vertical: ScrollBar { }
}
