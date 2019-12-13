import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12
import '..'

Page {
    background: Item {}
    header: Label {
        padding: 20
        text: qsTr('id_transactions')
        font.capitalization: Font.AllUppercase
    }

    ListView {
        anchors.leftMargin: 20
        anchors.fill: parent
        clip: true
        spacing: 32

        model: if (account) account.transactions

        delegate: TransactionDelegate {
            width: parent.width
            transaction: modelData
            first: index === 0
        }

        ScrollBar.vertical: ScrollBar { }
    }
}
