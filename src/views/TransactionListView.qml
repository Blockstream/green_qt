import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12
import '..'

ListView {
    id: transactions_view

    clip: true

    model: {
        account
        // TODO: temporary filter redeposit transactions (change outputs?)
        var txs = []
        if (account) {
            for (const tx of account.txs) {
                if (tx.type === 'redeposit') continue
                txs.push(tx)
            }
        }
        return txs;
    }

    delegate: TransactionDelegate {
        width: parent.width
        tx: modelData
        first: index === 0
        wallet: account.wallet
    }

    spacing: 0

    ScrollBar.vertical: ScrollBar { }
}
