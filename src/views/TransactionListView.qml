import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12
import '..'

ListView {
    clip: true

    model: {
        var txs = []
        if (!account) return []
        // TODO: temporary filter redeposit transactions (change outputs?)
        for (const tx of account.txs) {
            if (tx.type === 'redeposit') continue
            txs.push(tx)
        }
        return txs;
    }

    delegate: TransactionDelegate {
        width: parent.width
        tx: modelData
        first: index === 0
    }

    spacing: 0

    ScrollBar.vertical: ScrollBar { }
}
