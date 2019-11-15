import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

ScrollView {
    property Transaction transaction
    property string statusLabel

    function viewInExplorer() {
        Qt.openUrlExternally(`https://blockstream.info/testnet/tx/${transaction.data.txhash}`)
    }

    property Component test: Row {
        ToolButton {
            icon.source: 'assets/svg/arrow_left.svg'
            icon.height: 16
            icon.width: 16
            onClicked: stack_view.pop()
        }

        Image {
            source: transaction.data.type === 'outgoing' ? 'assets/svg/sent.svg' : 'assets/svg/received.svg'
        }

        Column {
            Layout.fillWidth: true

            Label {
                text: qsTr('id_transaction_details')
            }

            Label {
                text: statusLabel
            }
        }
    }

    id: scroll_view
    clip: true

    Column {
        y: 32
        width: scroll_view.width
        spacing: 32

        Column {
            spacing: 8

            Label {
                text: qsTr('id_received_on')
                color: 'gray'
            }

            Label {
                text: transaction.data.created_at
            }
        }

        Column {
            spacing: 8

            Label {
                text: qsTr('id_amount')
                color: 'gray'
            }

            Label {
                color: transaction.data.type === 'incoming' ? 'green' : 'white'
                text: `${transaction.data.type === 'incoming' ? '+' : '-'}${transaction.data.satoshi.btc / 100000000} BTC`
            }
        }

        Column {
            visible: transaction.data.type === 'outgoing'
            spacing: 8

            Label {
                text: qsTr('id_fee')
                color: 'gray'
            }

            Label {
                text: `${transaction.data.fee / 100000000} BTC (${Math.round(transaction.data.fee_rate / 1000)} sat/vB)`
            }
        }

        Column {
            spacing: 8
            width: parent.width

            Label {
                text: qsTr('id_my_notes')
                color: 'gray'
            }

            Row {
                TextArea {
                    id: memo_edit
                    placeholderText: qsTr('id_add_a_note_only_you_can_see_it')
                    text: transaction.data.memo
                }

                FlatButton {
                    text: qsTr('id_save')
                    visible: memo_edit.text !== transaction.data.memo
                    onClicked: transaction.updateMemo(memo_edit.text)
                }
            }
        }

        Page {
            header: Label {
                text: qsTr('id_transaction_id')
                color: 'gray'
            }
            background: MouseArea {
                onClicked: {
                    transaction.copyTxhashToClipboard()
                    ToolTip.show(qsTr('id_txhash_copied_to_clipboard'), 1000)
                }
            }
            ColumnLayout {
                RowLayout {
                    Label {
                        text: transaction.data.txhash
                    }
                    Image {
                        source: 'assets/svg/copy_to_clipboard.svg'
                    }
                }
                Button {
                    text: qsTr('id_view_in_explorer')
                    onClicked: viewInExplorer()
                }
            }
        }


        TextArea {
            visible: engine.debug
            width: parent.width
            text: JSON.stringify(transaction.data, null, '    ')
        }
    }
}
