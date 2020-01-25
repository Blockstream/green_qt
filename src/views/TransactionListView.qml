import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12
import '..'

ListView {
    clip: true
    spacing: 32

    model: account.transactions

    delegate: TransactionDelegate {
        width: parent.width
        transaction: modelData
    }

    ScrollBar.vertical: ScrollBar { }
}
