import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

Page {
    property Transaction transaction
    property string statusLabel

    function viewInExplorer() {
        Qt.openUrlExternally(`https://blockstream.info/testnet/tx/${transaction.data.txhash}`)
    }

    header: Pane {
        background: Rectangle {
            color: Qt.rgba(1, 1, 1, 0.01)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.05)
        }

        RowLayout {
            spacing: 16
            anchors.fill: parent

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
    }

    ScrollView {
        id: scroll_view
        clip: true
        anchors.fill: parent
        anchors.leftMargin: 64
        anchors.rightMargin: 64


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

            Column {
                spacing: 8

                Label {
                    text: qsTr('id_transaction_id')
                    color: 'gray'
                }

                Label {
                    text: transaction.data.txhash
                }

                FlatButton {
                    text: qsTr('id_copy_transaction_id')
                    onClicked: transaction.copyTxhashToClipboard()
                }
            }

            Button {
                text: qsTr('VIEW IN EXPLORER')
                onClicked: viewInExplorer()
            }

            TextArea {
                visible: engine.debug
                width: parent.width
                text: JSON.stringify(transaction.data, null, '    ')
            }
        }
    }
}
