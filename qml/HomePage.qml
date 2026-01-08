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
    signal transactionsClicked()
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
            Component.onCompleted: transaction_list_view.SplitView.preferredWidth = self.width / 2
            SplitView.minimumWidth: 400
            SplitView.preferredWidth: 500
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
                    font.pixelSize: 14
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
                        font.pixelSize: 14
                        font.weight: 600
                        text: qsTrId('id_latest_transactions')
                    }
                    LinkButton {
                        Layout.alignment: Qt.AlignCenter
                        font.pixelSize: 14
                        text: qsTrId('id_show_all')
                        onClicked: self.transactionsClicked()
                        visible: transaction_list_view.count > 0
                    }
                }
                Item {
                    Layout.minimumHeight: 8
                }
                Repeater {
                    id: payments_repeater
                    model: PaymentModel {
                        context: self.context
                    }
                    delegate: PaymentDelegate {
                        Layout.topMargin: 10
                        Layout.fillWidth: true
                    }
                }
                Item {
                    Layout.minimumHeight: 8
                    visible: payments_repeater.count > 0
                }
                Label {
                    color: '#929292'
                    font.pixelSize: 14
                    text: `You don't have any transactions yet.`
                    visible: transaction_list_view.count === 0 && payments_repeater.count === 0
                }
            }
            footer: Item {
                implicitHeight: 12
            }
            model: LimitModel {
                limit: 10
                source: TransactionModel {
                    context: self.context
                }
            }
            delegate: TransactionDelegate2 {
                id: delegate
                onClicked: self.transactionClicked(delegate.transaction)
            }
        }
        VFlickable {
            SplitView.fillWidth: true
            SplitView.minimumWidth: 300
            alignment: Qt.AlignTop
            Label {
                Layout.alignment: Qt.AlignTop
                Layout.bottomMargin: 8
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                elide: Label.ElideRight
                font.pixelSize: 14
                font.weight: 600
                text: 'Bitcoin Price'
            }
            LineChart {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 300
                Layout.maximumHeight: 400
                selectedIndex: 0
                showRangeButtons: true
                verticalGridLinesCount: 5
                context: self.context
            }
            Repeater {
                id: promos_repeater
                model: {
                    return [...PromoManager.promos]
                        .filter(_ => !Settings.useTor)
                        .filter(promo => !promo.dismissed)
                        .filter(promo => promo.ready)
                        .filter(promo => UtilJS.filterPromo(WalletManager.wallets, promo))
                        .filter(promo => promo.data.is_visible)
                        .filter(promo => promo.data.screens.indexOf('HomeTab') >= 0)
                        .slice(0, 1)
                }
                delegate: PromoCard {
                    required property Promo modelData
                    Layout.fillWidth: true
                    Layout.minimumHeight: 250
                    Layout.topMargin: 32
                    id: card
                    promo: card.modelData
                    screen: 'WalletOverview'
                    onClicked: {
                        const context = self.context
                        const promo = card.promo
                        const screen = 'WalletOverview'
                        if (card.promo.data.is_small) {
                            Analytics.recordEvent('promo_action', AnalyticsJS.segmentationPromo(Settings, context, promo, screen))
                            Qt.openUrlExternally(card.promo.data.link)
                        } else {
                            Analytics.recordEvent('promo_open', AnalyticsJS.segmentationPromo(Settings, context, promo, screen))
                            promo_drawer.createObject(self, { context, promo, screen }).open()
                        }
                    }
                }
            }
            VSpacer {
                Layout.minimumHeight: 12
            }
        }
    }

    Component {
        id: promo_drawer
        PromoDrawer {
        }
    }

    component DebugPaymentDelegate: AbstractButton {
        required property int index
        required property Payment payment
        id: delegate
        leftPadding: 24
        rightPadding: 24
        topPadding: 12
        bottomPadding: 12
        background: Rectangle {
            border.color: '#262626'
            border.width: 1
            color: Qt.lighter('#181818', delegate.enabled && delegate.hovered ? 1.2 : 1)
            radius: 8
        }
        contentItem: Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            color: delegate.payment.transaction ? 'green' : 'red'
            font.pixelSize: 10
            text: JSON.stringify(delegate.payment.data, null, 4)
            wrapMode: Label.WordWrap
        }
    }
    component PaymentDelegate: AbstractButton {
        required property int index
        required property Payment payment
        id: delegate
        leftPadding: 24
        rightPadding: 24
        topPadding: 12
        bottomPadding: 12
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
                source: UtilJS.transactionIcon('incoming', 0)
            }
            ColumnLayout {
                Layout.fillWidth: false
                Layout.fillHeight: false
                Layout.alignment: Qt.AlignCenter
                spacing: 0
                Label {
                    color: '#FFF'
                    font.pixelSize: 14
                    font.weight: 600
                    text: qsTrId('id_received')
                }
                Label {
                    color: '#929292'
                    text: delegate.payment.updatedAt.toLocaleString(locale.dateTimeFormat(Locale.LongFormat))
                    font.pixelSize: 14
                    font.weight: 400
                    font.capitalization: Font.AllUppercase
                    opacity: 0.6
                }
            }
            HSpacer {
            }
            TransactionStatusBadge {
                confirmations: 0
                liquid: false
            }
            ColumnLayout {
                Layout.alignment: Qt.AlignRight
                Label {
                    Layout.alignment: Qt.AlignRight
                    color: '#00BCFF'
                    font.pixelSize: 14
                    font.weight: 600
                    text: UtilJS.incognito(Settings.incognito, `${delegate.payment.data.destinationAmount} ${delegate.payment.data.destinationCurrencyCode}`)
                }
                Label {
                    Layout.alignment: Qt.AlignRight
                    color: '#929292'
                    font.pixelSize: 12
                    font.weight: 400
                    text: UtilJS.incognito(Settings.incognito, `${delegate.payment.data.sourceAmount} ${delegate.payment.data.sourceCurrencyCode}`)
                }
            }
            RightArrowIndicator {
                active: false
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
                source: UtilJS.transactionIcon(delegate.transaction.data.type, transactionConfirmations(delegate.transaction))
            }
            ColumnLayout {
                Layout.fillWidth: false
                Layout.fillHeight: false
                Layout.alignment: Qt.AlignCenter
                spacing: 0
                Label {
                    color: '#FFF'
                    font.pixelSize: 14
                    font.weight: 600
                    text: UtilJS.transactionTypeLabel(delegate.transaction)
                }
                Label {
                    color: '#929292'
                    text: UtilJS.formatTransactionTimestamp(delegate.transaction)
                    font.pixelSize: 14
                    font.weight: 400
                    font.capitalization: Font.AllUppercase
                    opacity: 0.6
                }
            }
            HSpacer {
            }
            Image {
                source: 'qrc:/ffffff/24/note.svg'
                visible: delegate.transaction.memo.length > 0
            }
            TransactionAmounts {
                Layout.fillWidth: false
                Layout.minimumWidth: delegate.width / 5
                context: self.context
                transaction: delegate.transaction
            }
            RightArrowIndicator {
                active: delegate.hovered
            }
        }
    }
}
