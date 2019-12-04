import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

Page {
    property Transaction transaction
    property string statusLabel

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

    background: Item {}

    header: RowLayout {
        ToolButton {
            id: back_arrow_button
            icon.source: 'assets/svg/arrow_left.svg'
            icon.height: 16
            icon.width: 16
            onClicked: stack_view.pop()
        }

        Label {
            text: qsTr('id_transaction_details') + ' - ' + tx_direction(transaction.data.type)
            font.pixelSize: 14
            font.capitalization: Font.AllUppercase
        }

        Label {
            text: transaction.data.type === 'outgoing' ? 'SENT' : 'RECEIVED' //qsTr('id_transaction_details')
            Layout.fillWidth: true
        }
        Button {
            Layout.rightMargin: 32
            flat: true
            text: qsTr('id_view_in_explorer')
            onClicked: transaction.openInExplorer()
        }
    }

    ScrollView {
        id: scroll_view
        anchors.fill: parent
        anchors.leftMargin: 20
        clip: true

        Column {
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
                    text: qsTr('id_transaction_status')
                    color: 'gray'
                }

                Label {
                    text: statusLabel
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
                }
            }

            TextArea {
                visible: engine.debug
                width: parent.width
                text: JSON.stringify(transaction.data, null, '    ')
            }
        }
    }
}
