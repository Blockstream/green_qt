import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

Pane {
    property Transaction transaction
    property var tx: transaction.data
    property bool first
    property int confirmations: tx.block_height === 0 ? 0 : 1 + wallet.events.block.block_height - tx.block_height
    property string statusLabel: {
        if (confirmations === 0) return qsTr('id_unconfirmed')
        if (confirmations < 6) return qsTr('id_d6_confirmations').arg(confirmations)
        return qsTr('id_completed')
    }

    function pretty(d) {
        if (d < 10) return qsTr('id_now')
        if (d < 60) return qsTr('LAST MINUTE')
        if (d < 600) return qsTr(`LAST ${Math.ceil(d / 60)} MINUTES`)

        d = Math.ceil(d / 3600)
        if (d < 2) return qsTr('LAST HOUR')
        if (d < 24) return qsTr('TODAY')

        d = Math.ceil(d / 24)
        return qsTr(`${d} DAYS AGO`)
    }


    Timer {
        id: timer
        interval: 1000; running: true; repeat: true
        onTriggered: now = (new Date()).getTime()
        property var now: (new Date()).getTime()
    }

    property var secs: Math.ceil((timer.now - (new Date(tx.created_at)).getTime()) / 1000) - 3600

    spacing: 8
    padding: 0

    background: MouseArea {
        anchors.fill: parent
        onClicked: stack_view.push(transaction_view_component, { statusLabel: statusLabel, transaction: transaction })
    }

    function address(tx) {
        if (tx.type === 'incoming') {
            for (const o of tx.outputs) {
                if (o.is_relevant) {
                    return o.address
                }
            }
        }
        if (tx.type === 'outgoing') {
            return tx.addressees[0]
        }
        if (tx.type === 'redeposit') {
            return qsTr("id_redeposited")
        }
        return JSON.stringify(tx, null, '\t')
    }

    RowLayout {
        spacing: 16
        anchors.fill: parent

        Image {
            source: tx.type === 'incoming' ? 'assets/svg/received.svg' : 'assets/svg/sent.svg'
        }

        ColumnLayout {
            Layout.fillWidth: true
            Label {
                Layout.fillWidth: true
                text: pretty(secs)
                opacity: 0.8
            }
            Label {
                Layout.fillWidth: true
                font.pixelSize: 14
                text: address(tx)
            }
        }

        Column {
            Label {
                anchors.right: parent.right
                color: tx.type === 'incoming' ? 'green' : 'white'
                text: `${tx.type === 'incoming' ? '+' : '-'}${tx.satoshi.btc / 100000000} BTC`
            }

            Label {
                anchors.right: parent.right
                color: confirmations === 0 ? 'red' : 'white'
                text: statusLabel
            }
        }

        ToolButton {
            text: qsTr('⋮')
            onClicked: menu.open()

            Menu {
                id: menu

                MenuItem {
                    text: qsTr('id_view_in_explorer')
                    onTriggered: Qt.openUrlExternally(`https://blockstream.info/testnet/tx/${tx.txhash}`)
                }

                MenuItem {
                    enabled: false
                    text: qsTr('id_increase_fee')
                }

                MenuSeparator { }

                MenuItem {
                    text: qsTr('id_copy_transaction_id')
                    onTriggered: transaction.copyTxhashToClipboard()
                }

                MenuItem {
                    enabled: false
                    text: qsTr('id_copy_details')
                }

                MenuItem {
                    enabled: false
                    text: qsTr('id_copy_raw_transaction')
                }
            }
        }
    }
}
