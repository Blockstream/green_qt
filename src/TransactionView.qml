import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

Page {
    property var transaction

    function viewInExplorer() {
        Qt.openUrlExternally(`https://blockstream.info/testnet/tx/${transaction.txhash}`)
    }

    header: RowLayout {
        spacing: 16

        ToolButton {
            icon.source: 'assets/assets/svg/arrow_left.svg'
            icon.height: 16
            icon.width: 16
            onClicked: stack_view.pop()
        }

        Label {
            text: transaction.txhash
            Layout.fillWidth: true
        }

        FlatButton {
            text: qsTr('VIEW IN EXPLORER')
            onClicked: viewInExplorer()
        }
    }

    SplitView {

        anchors.fill: parent

        Pane {
            Layout.fillWidth: true
            ColumnLayout {

                Image {
                    Layout.leftMargin: 8
                    source: transaction.type === 'outgoing' ? 'assets/assets/svg/sent.svg' : 'assets/assets/svg/received.svg'
                }

                Label {
                    text: transaction.type + ' ' + transaction.created_at
                }

                Label {
                    text: qsTr('AMOUNT')
                }

                Label {
                    text: transaction.satoshi.btc
                }

                Label {
                    text: 'FEE AMOUNT, SIZE, FEE RATE'
                }
                RowLayout {
                    Label {
                        text: transaction.fee
                    }

                    Label {
                        text: transaction.transaction_size
                    }

                    Label {
                        text: transaction.fee_rate
                    }
                }

                Label {
                    text: qsTr('MY NOTES')
                }

                TextArea {
                    text: transaction.memo
                }
            }
        }

        ScrollView {
            TextArea {
                Layout.fillWidth: true
                text: JSON.stringify(transaction, null, '    ')
            }
        }

    }
}
/*

SHARE?

DATA
(ELAPSED ?))

 OUTGOING/INCOMING

RECIPIENT (JUST FOR OUTGOING)

AMOUNT

BTC / USD

FEE AMOUNT, SIZE, FEE RATE



*/
