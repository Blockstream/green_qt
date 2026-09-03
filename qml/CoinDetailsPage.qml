import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    required property Output output
    required property string unit

    readonly property AccountTransaction transaction: self.output.account.getTransactionByTxHash(self.output.data.txhash ?? '')
    readonly property var transactionOutput: {
        const outputs = self.transaction?.data.outputs ?? []
        return outputs.find(value => Number(value.pt_idx) === Number(self.output.data.pt_idx)) ?? null
    }
    readonly property string receivingAddress: self.output.address || self.output.data.address || self.transactionOutput?.address || ''
    readonly property string explorerUrl: {
        const transactionUrl = String(self.transaction?.url ?? '')
        if (transactionUrl.length > 0) return transactionUrl
        const txhash = self.output.data.txhash ?? ''
        const baseUrl = self.output.account.network.data.tx_explorer_url ?? ''
        return txhash.length > 0 && baseUrl.length > 0 ? baseUrl + txhash : ''
    }

    id: self
    title: 'Coin Details'
    leftItem: BackButton {
        onClicked: self.popPage()
    }
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }

    Convert {
        id: convert
        account: self.output.account
        asset: self.output.asset
        input: ({ satoshi: String(self.output.data.satoshi ?? 0) })
        unit: self.unit
    }

    contentItem: VFlickable {
        alignment: Qt.AlignTop
        spacing: 32

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8

            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: 96
                Layout.preferredWidth: 96
                AssetIcon {
                    anchors.centerIn: parent
                    asset: self.output.asset
                    size: 72
                }
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                color: '#FFFFFF'
                font.pixelSize: 20
                font.weight: 600
                text: UtilJS.shortenOutpoint(self.output.data.txhash, self.output.data.pt_idx)
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                color: '#A0A0A0'
                font.pixelSize: 12
                text: self.transaction?.data.created_at_ts
                    ? UtilJS.formatTransactionTimestamp(self.transaction, Qt.locale())
                    : ''
                visible: text.length > 0
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                color: '#A0A0A0'
                font.pixelSize: 12
                text: self.output.unconfirmed ? qsTrId('id_unconfirmed') : 'Confirmed'
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6

                Label {
                    color: '#FFFFFF'
                    font.family: 'Roboto Mono'
                    font.features: { 'calt': 0, 'zero': 1 }
                    font.pixelSize: 28
                    font.weight: 500
                    text: UtilJS.incognito(Settings.incognito, convert.output.amount)
                }

                Label {
                    Layout.alignment: Qt.AlignBaseline
                    color: '#00BCFF'
                    font.pixelSize: 12
                    font.weight: 600
                    text: convert.output.unit
                }
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                color: '#A0A0A0'
                font.pixelSize: 14
                text: UtilJS.incognito(Settings.incognito, convert.fiat.label)
                visible: convert.fiat.available
            }
        }

        LineSeparator {
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 20
            rowSpacing: 12

            Label {
                Layout.alignment: Qt.AlignTop
                Layout.minimumWidth: 100
                color: '#929292'
                font.pixelSize: 14
                font.weight: 400
                text: qsTrId('id_received_on')
                visible: self.receivingAddress.length > 0
            }

            AddressLabel {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                address: self.receivingAddress
                copyEnabled: true
                elide: AddressLabel.ElideNone
                font.pixelSize: 14
                font.weight: 400
                horizontalAlignment: Text.AlignRight
                visible: self.receivingAddress.length > 0
            }

            Label {
                Layout.alignment: Qt.AlignTop
                color: '#929292'
                font.pixelSize: 14
                font.weight: 400
                text: qsTrId('id_transaction_id')
                visible: (self.output.data.txhash ?? '').length > 0
            }

            InlineCopyableLabel {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                color: '#FFFFFF'
                elide: Label.ElideMiddle
                font.family: 'Roboto Mono'
                font.features: { 'calt': 0, 'zero': 1 }
                font.pixelSize: 14
                font.weight: 400
                horizontalAlignment: Text.AlignRight
                text: self.output.data.txhash ?? ''
                visible: text.length > 0
            }

            Label {
                color: '#929292'
                font.pixelSize: 14
                font.weight: 400
                text: 'Output Index'
                visible: self.output.data.pt_idx !== undefined
            }

            Label {
                Layout.fillWidth: true
                color: '#FFFFFF'
                font.pixelSize: 14
                font.weight: 400
                horizontalAlignment: Text.AlignRight
                text: self.output.data.pt_idx === undefined ? '' : String(self.output.data.pt_idx)
                visible: text.length > 0
            }

            Label {
                color: '#929292'
                font.pixelSize: 14
                font.weight: 400
                text: 'Script Type'
                visible: (self.output.data.address_type ?? '').length > 0
            }

            Label {
                Layout.fillWidth: true
                color: '#FFFFFF'
                font.pixelSize: 14
                font.weight: 400
                horizontalAlignment: Text.AlignRight
                text: self.output.data.address_type ?? ''
                visible: text.length > 0
            }

            Label {
                color: '#929292'
                font.pixelSize: 14
                font.weight: 400
                text: qsTrId('id_block_height')
                visible: Number(self.output.data.block_height ?? 0) > 0
            }

            Label {
                Layout.fillWidth: true
                color: '#FFFFFF'
                font.pixelSize: 14
                font.weight: 400
                horizontalAlignment: Text.AlignRight
                text: Number(self.output.data.block_height ?? 0) > 0 ? String(self.output.data.block_height) : ''
                visible: text.length > 0
            }

            Label {
                Layout.alignment: Qt.AlignTop
                color: '#929292'
                font.pixelSize: 14
                font.weight: 400
                text: qsTrId('id_note')
                visible: (self.transaction?.memo ?? '').length > 0
            }

            InlineCopyableLabel {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                color: '#FFFFFF'
                font.pixelSize: 14
                font.weight: 400
                horizontalAlignment: Text.AlignRight
                text: self.transaction?.memo ?? ''
                visible: text.length > 0
                wrapMode: Label.WordWrap
            }
        }

        VSpacer {
        }
    }

    footerItem: ColumnLayout {
        LinkButton {
            Layout.alignment: Qt.AlignCenter
            external: true
            font.pixelSize: 16
            text: qsTrId('id_view_in_explorer')
            visible: self.explorerUrl.length > 0
            onClicked: Qt.openUrlExternally(self.explorerUrl)
        }
    }

    component LineSeparator: Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        height: 1
        color: '#313131'
    }
}
