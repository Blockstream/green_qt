import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

ScrollView {
    property Transaction transaction
    property string statusLabel
    font.family: dinpro.name

    function tx_direction(type) {
        switch (type) {
            case 'incoming':
                return qsTr('id_incoming')
            case 'outgoing':
                return qsTr('id_outgoing')
            case 'redeposit':
                return qsTr('id_redeposited')

        }
    }

    property Component test: Row {
        ToolButton {
            id: back_arrow_button
            icon.source: 'assets/svg/arrow_left.svg'
            icon.height: 16
            icon.width: 16
            onClicked: stack_view.pop()
        }

        Label {
            anchors.verticalCenter: back_arrow_button.verticalCenter
            text: qsTr('id_transaction_details') + ' - ' + tx_direction(transaction.data.type)
            font.family: dinpro.name
            font.pixelSize: 14
            font.capitalization: Font.AllUppercase
        }
    }

    id: scroll_view
    clip: true

    Column {
        y: 32
        width: scroll_view.width
        spacing: 26

        Column {
            spacing: 8
            Label {
                text: 'Transaction Status' // TODO: add to translations
                font.pixelSize: 14
                color: 'gray'
            }

            Label {
                text: statusLabel
                font.pixelSize: 18
            }
        }

        Column {
            spacing: 8

            Label {
                text: qsTr('id_received_on')
                font.pixelSize: 14
                color: 'gray'
            }

            Label {
                text: transaction.data.created_at
                font.pixelSize: 18
            }
        }

        Column {
            spacing: 8

            Label {
                text: qsTr('id_amount')
                font.pixelSize: 14
                color: 'gray'
            }

            Label {
                color: transaction.data.type === 'incoming' ? 'green' : 'white'
                text: `${transaction.data.type === 'incoming' ? '+' : '-'}${transaction.data.satoshi.btc / 100000000} BTC`
                font.pixelSize: 18
            }
        }

        Column {
            visible: transaction.data.type === 'outgoing'
            spacing: 8

            Label {
                text: qsTr('id_fee')
                color: 'gray'
                font.pixelSize: 14
            }

            Label {
                text: `${transaction.data.fee / 100000000} BTC (${Math.round(transaction.data.fee_rate / 1000)} sat/vB)`
                font.pixelSize: 18
            }
        }

        Column {
            spacing: 8
            width: parent.width

            Label {
                text: qsTr('id_my_notes')
                color: 'gray'
                font.pixelSize: 14
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
                font.pixelSize: 14
            }
            background: MouseArea {
                onClicked: {
                    transaction.copyTxhashToClipboard()
                    ToolTip.show(qsTr('id_txhash_copied_to_clipboard'), 1000)
                }
            }
            ColumnLayout {
                spacing: 8
                RowLayout {
                    spacing: 5
                    Label {
                        text: transaction.data.txhash
                        font.pixelSize: 14
                    }
                    Image {
                        source: 'assets/svg/copy_to_clipboard.svg'
                    }
                }
                Button {
                    text: qsTr('id_view_in_explorer')
                    onClicked: transaction.openInExplorer()
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
