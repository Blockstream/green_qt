import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

Pane {
    property var tx
    property bool first
    property alias wallet: amount_converter.wallet

    function pretty(d) {
        if (d < 10) return qsTr('JUST NOW')
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

    background: Rectangle {
        Rectangle {
            id: separator
            visible: !first
            height: 1
            width: parent.width
            border.width: 1
            color: 'transparent'
            border.color: Qt.rgba(0, 0, 0, 0.05)

        }

        MouseArea {
            id: ma
            hoverEnabled: true
            anchors.fill: parent

            onClicked: stack_view.push(transaction_view_component, { transaction: tx })
        }
        color: secs < 60 ? Qt.rgba(0.5, 1, 0.5, ma.containsMouse ? 0.2 : 0.1) : Qt.rgba(1, 1, 1, ma.containsMouse ? 0.1 : 0)
    }

    AmountConverter {
        id: amount_converter
        input: ({ btc: '' + (tx.satoshi.btc / 100000000) })
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

        return JSON.stringify(tx, null, '\t')
    }

    RowLayout {
        anchors.fill: parent
        spacing: 8

        Image {
            Layout.leftMargin: 8
            source: tx.type === 'outgoing' ? 'assets/assets/svg/sent.svg' : 'assets/assets/svg/received.svg'
        }

        ColumnLayout {
            Layout.fillWidth: true
            Label {
                Layout.fillWidth: true
                //font.pixelSize: 20
                text: pretty(secs)
                opacity: 0.8
            }
            Label {
                Layout.fillWidth: true
                font.pixelSize: 14
                text: address(tx)
            }
        }

        /*
            Label {
                font.pixelSize: 10
                text: qsTr('FEE ') + (tx.fee / 100000000).toFixed(8) + ' BTC'
            }
            Label {
                font.pixelSize: 10
                wrapMode: Text.Wrap
                text: JSON.stringify(tx, null, '    ')
            }
        }*/

        ColumnLayout {
            Layout.fillWidth: false

            Layout.alignment: Qt.AlignRight

            Amount {
                Layout.alignment: Qt.AlignRight
                pixelSize: 14

                amount: (tx.type === 'incoming' ? '' : '-') + amount_converter.input.btc
                currency: 'BTC'
                currencyBorder: false
            }

            Amount {
                Layout.alignment: Qt.AlignRight

                amount: amount_converter.valid ? (tx.type === 'incoming' ? '' : '-') + amount_converter.output.fiat : ''
                currency: amount_converter.valid ? amount_converter.output.fiat_currency : ''
                currencyBorder: false
            }
            Layout.rightMargin: 16
        }

        TextField {
            id: txhash_field
            visible: false
            text: tx.txhash
        }

        ToolButton {
            text: qsTr('⋮')
            onClicked: menu.open()

            Menu {
                id: menu

                MenuItem {
                    text: qsTr('VIEW IN EXPLORER')
                    onTriggered: Qt.openUrlExternally(`https://blockstream.info/testnet/tx/${tx.txhash}`)
                }

                MenuItem {
                    enabled: false
                    text: qsTr('INCREASE FEE')
                }

                MenuSeparator { }

                MenuItem {
                    text: qsTr('COPY TXID')
                    onTriggered: {
                        // TODO: should have a slot somewhere to copy
                        // and remove the auxiliary txhash_field above
                        txhash_field.selectAll()
                        txhash_field.copy()
                    }
                }

                MenuItem {
                    enabled: false
                    text: qsTr('COPY DETAILS')
                }

                MenuItem {
                    enabled: false
                    text: qsTr('COPY RAW')
                }
            }
        }
    }
}
