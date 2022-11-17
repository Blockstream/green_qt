import Blockstream.Green.Core 0.1
import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

import "analytics.js" as AnalyticsJS

ControllerDialog {
    required property Account account

    id: self
    title: qsTrId('id_send')
    icon: 'qrc:/svg/send.svg'
    autoDestroy: true
    wallet: self.account.wallet
    controller: SendController {
        account: self.account
        balance: send_view.balance
        address: send_view.address
        sendAll: send_view.sendAll
        manualCoinSelection: send_view.manualCoinSelection
        utxos: {
            var r = {}
            for (const u of send_view.selectedOutputs) {
                const policy = u.asset ? u.asset.id : 'btc'
                if (policy in r) {
                    r[policy].push(u.data)
                } else {
                    r[policy] = [u.data]
                }
            }
            return r
        }
        onFinished: {
            Analytics.recordEvent('send_transaction', AnalyticsJS.segmentationTransaction(self.account, {
                address_input: send_view.address_input,
                transaction_type: 'send',
                with_memo: self.controller.memo !== '',
            }))
        }
        onError: {
            Analytics.recordEvent('failed_transaction', AnalyticsJS.segmentationSession(self.account.wallet))
        }
    }
    doneText: qsTrId('id_transaction_sent')
    minimumWidth: 500
    minimumHeight: 300
    initialItem: SendView {
        id: send_view
        account: self.account
    }
    doneComponent: TransactionDoneView {
        account: self.account
        dialog: self
        transaction: self.controller.signedTransaction
    }

    AnalyticsView {
        name: 'Send'
        active: self.opened
        segmentation: AnalyticsJS.segmentationSubAccount(self.account)
    }
}
