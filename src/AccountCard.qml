import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

Pane {
    property var account
    width: 180

    background: Rectangle {
        color: Qt.rgba(1, 1, 1, 0.5)
        opacity: accounts_list_view.currentIndex === index ? 0.2 : 0.05
//        border.width: 1
//        border.color: 'white'
//        radius: 3

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: accounts_list_view.currentIndex = index
        }
    }

    AmountConverter {
        id: converter
        wallet: account ? account.wallet : null
        input: ({ btc: account ? account.json.balance.btc.btc : 0 })
    }

    ColumnLayout {
        spacing: 2
        anchors.fill: parent
        Label {
            Layout.margins: 4
            text: account.name
            //font.italic: account ? account.json.name === '' : false
            //font.pixelSize: 14
            //font.bold: true
        }
        Amount {
            Layout.alignment: Qt.AlignRight
            amount: account ? account.json.balance.btc.btc : 0
            currencyBorder: false
            //currency: 'BTC'
        }
        Amount {
            Layout.alignment: Qt.AlignRight
            amount: converter.valid ? converter.output.fiat : 0
            currency: converter.valid ? converter.output.fiat_currency : ''
            currencyBorder: false
        }
    }
}
