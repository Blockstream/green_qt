import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtQml

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

Page {
    signal assetClicked(Asset asset)
    signal transactionClicked(Transaction transaction)
    required property Context context
    id: self
    background: null
    padding: 0
    contentItem: SplitView {
        id: split_view
        focusPolicy: Qt.ClickFocus
        handle: Item {
            implicitWidth: 32
            implicitHeight: split_view.height
        }
        TListView {
            SplitView.fillWidth: true
            SplitView.minimumWidth: 400
            id: transaction_list_view
            contentY: 0
            spacing: 8
            header: ColumnLayout {
                onHeightChanged: transaction_list_view.contentY = -(transaction_list_view.headerItem?.height ?? 0)
                spacing: 0
                width: ListView.view.width
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    Layout.bottomMargin: 8
                    elide: Label.ElideRight
                    font.pixelSize: 18
                    font.weight: 600
                    text: qsTrId('id_assets')
                }
                AssetsView {
                    Layout.fillWidth: true
                    context: self.context
                    onAssetClicked: (asset) => self.assetClicked(asset)
                }
                RowLayout {
                    Layout.topMargin: 32
                    Label {
                        Layout.alignment: Qt.AlignCenter
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        elide: Label.ElideRight
                        font.pixelSize: 18
                        font.weight: 600
                        text: qsTrId('id_transactions')
                    }
                    LinkButton {
                        Layout.alignment: Qt.AlignCenter
                        font.pixelSize: 16
                        text: 'See all'
                    }
                }
                Item {
                    Layout.minimumHeight: 8
                }
            }
            model: TransactionModel {
                context: self.context
            }
            delegate: TransactionDelegate2 {
                id: delegate
                onClicked: self.transactionClicked(delegate.transaction)
            }
        }
        VFlickable {
            SplitView.fillWidth: true
            SplitView.preferredWidth: 500
            SplitView.minimumWidth: 300
            SplitView.maximumWidth: 600
            alignment: Qt.AlignTop
            Label {
                Layout.bottomMargin: 8
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                elide: Label.ElideRight
                font.pixelSize: 18
                font.weight: 600
                text: 'Bitcoin Price'
            }
            LineChart {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 400
                selectedIndex: 0
                showRangeButtons: true
                verticalGridLinesCount: 5
            }

        }
    }

    component TransactionDelegate2: ItemDelegate {
        required property Transaction transaction
        id: delegate
        leftPadding: 24
        rightPadding: 24
        topPadding: 12
        bottomPadding: 12
        width: ListView.view.width
        background: Rectangle {
            border.color: '#262626'
            border.width: 1
            color: Qt.lighter('#181818', delegate.enabled && delegate.hovered ? 1.2 : 1)
            radius: 8
        }
        contentItem: RowLayout {
            spacing: 8
            Image {
                Layout.alignment: Qt.AlignCenter
                source: `qrc:/svg2/tx-${delegate.transaction.data.type}.svg`
            }
            ColumnLayout {
                Layout.fillWidth: false
                Layout.fillHeight: false
                Layout.alignment: Qt.AlignCenter
                spacing: 0
                Label {
                    color: '#FFF'
                    font.pixelSize: 16
                    font.weight: 600
                    text: delegate.transaction.data.type
                }
                Label {
                    color: '#929292'
                    text: UtilJS.formatTransactionTimestamp(delegate.transaction.data)
                    font.pixelSize: 16
                    font.weight: 400
                    font.capitalization: Font.AllUppercase
                    opacity: 0.6
                }
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: 0
                Layout.fillWidth: true
                color: '#929292'
                font.pixelSize: 12
                font.weight: 400
                text: {
                    const lines = delegate.transaction.memo.trim().split('\n')
                    return lines[0] + (lines.length > 1 ? '...' : '')
                }
                wrapMode: Label.Wrap
            }
            ColumnLayout {
                Layout.fillWidth: false
                Layout.minimumWidth: delegate.width / 5
                spacing: 1
                Repeater {
                    model: {
                        const transaction = delegate.transaction
                        const account = transaction.account
                        const context = account.context
                        const assets = []
                        if (delegate.transaction.type !== Transaction.Redeposit) {
                            if (account.network.liquid) {
                                for (const [id, satoshi] of Object.entries(transaction.data.satoshi)) {
                                    if (account.network.policyAsset === id) continue
                                    const asset = AssetManager.assetWithId(context.deployment, id)
                                    assets.push({ asset, satoshi: String(satoshi) })
                                }
                            }
                        }
                        return assets
                    }
                    delegate: Label {
                        Convert {
                            id: convert
                            account: delegate.transaction.account
                            asset: modelData.asset
                            input: ({ satoshi: modelData.satoshi })
                        }
                        Layout.alignment: Qt.AlignRight
                        color: delegate.transaction.data.type === 'incoming' ? '#00BCFF' : '#FFF'
                        font.pixelSize: 14
                        font.weight: 600
                        text: UtilJS.incognito(Settings.incognito, convert.output.label)
                    }
                }
                Convert {
                    id: convert
                    account: delegate.transaction.account
                    input: {
                        const network = delegate.transaction.account.network
                        const satoshi = delegate.transaction.data.satoshi
                        return { satoshi: String(satoshi[network.policyAsset] ?? 0) }
                    }
                    unit: delegate.transaction.account.session.unit
                }
                Label {
                    Layout.alignment: Qt.AlignRight
                    color: delegate.transaction.data.type === 'incoming' ? '#00BCFF' : '#FFF'
                    font.pixelSize: 14
                    font.weight: 600
                    text: UtilJS.incognito(Settings.incognito, convert.output.label)
                    visible: Number(convert.result.satoshi ?? '0') !== 0
                }
                Label {
                    Layout.alignment: Qt.AlignRight
                    color: '#929292'
                    font.pixelSize: 12
                    font.weight: 400
                    text: UtilJS.incognito(Settings.incognito, convert.fiat.label)
                    visible: Number(convert.result.satoshi ?? '0') !== 0
                }
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                Layout.leftMargin: 10
                source: 'qrc:/svg2/right.svg'
            }
        }
    }
}
