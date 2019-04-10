import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

Page {
    topPadding: 0
    bottomPadding: 0

    header: Pane {
        topPadding: 0
        bottomPadding: 0

        background: Rectangle {
            color: 'white'
            opacity: 0.05
        }

        RowLayout {
            anchors.fill: parent

            Label {
                text: qsTr('OVERVIEW')
            }

            Item {
                Layout.fillWidth: true
            }

            ToolButton {
                icon.source: 'assets/assets/svg/cancel.svg'
                icon.width: 8
                icon.height: 8
            }
        }
    }

    ScrollView {
        clip:true
        anchors.fill: parent
        ColumnLayout {
            AmountConverter {
                id: converter
                wallet: account ? account.wallet : null
                input: ({ btc: account ? account.json.balance.btc.btc : 0 })
            }

            Amount {
                Layout.alignment: Qt.AlignRight
                amount: account ? account.json.balance.btc.btc : 0
                pixelSize: 16
                currency: 'BTC'
                currencyBorder: false
            }
            Amount {
                Layout.alignment: Qt.AlignRight
                amount: converter.valid ? converter.output.fiat : 0
                currency: converter.valid ? converter.output.fiat_currency : ''
                pixelSize: 16
                currencyBorder: false
            }
        }
    }
}
