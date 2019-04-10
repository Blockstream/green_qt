import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

Rectangle {
    id: delegate

    color: Qt.rgba(0, 0, 0, 0.2)

    property var account

    width: parent.width - 8
    height: col.height + 16

    AmountConverter {
        id: converter
        wallet: account ? account.wallet : null
        input: ({ btc: account ? account.json.balance.btc.btc : 0 })
    }

    Column {
        id: col
        x: 8
        y: 8
        width: parent.width - 20

        Label {
            text: account ? account.json.name === '' ? qsTr('Main Account') : account.json.name : ''
            font.italic: account ? account.json.name === '' : false
        }

        Row {
            spacing: 16

            Amount {
                amount: account ? account.json.balance.btc.btc : 0
                currency: 'BTC'
            }
            Amount {
                amount: converter.valid ? converter.output.fiat : 0
                currency: converter.valid ? converter.output.fiat_currency : ''
                currencyBorder: false
            }
            Label {

            }
        }

        Text {
            visible: false
            width: parent.width
            color: delegate.ListView.isCurrentItem ? 'white' : 'black';
            text: account ? JSON.stringify(account.json, null, '\t') : ''
            wrapMode: Text.WrapAnywhere
        }
    }
}
