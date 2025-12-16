import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    signal quoteClicked(var quote)
    required property var quotes
    required property var quoteService
    id: self
    footer: null
    title: 'Change Exchange'
    contentItem: VFlickable {
        alignment: Qt.AlignTop
        clip: false
        spacing: 8
        Repeater {
            model: self.quotes
            delegate: QuoteDelegate {
                required property var modelData
                id: delegate
                quote: delegate.modelData
            }
        }
        VSpacer {
        }
    }

    component QuoteDelegate: ItemDelegate {
        required property var quote
        property bool isBestPrice: {
            const provider = delegate.quote.serviceProvider
            const bestProvider = self.quoteService.bestServiceProvider
            return provider === bestProvider
        }
        property bool isSelected: {
            const selected = self.quoteService.selectedQuote
            return delegate.quote.serviceProvider === selected.serviceProvider &&
                Math.abs((delegate.quote.destinationAmount || 0) - (selected.destinationAmount || 0)) < 0.00000001
        }
        Layout.fillWidth: true
        id: delegate
        highlighted: delegate.isSelected
        leftPadding: 20
        rightPadding: 20
        topPadding: 20
        bottomPadding: 20
        padding: 20
        background: Rectangle {
            id: background
            color: Qt.lighter(delegate.highlighted ? '#062F4A' : '#181818', delegate.hovered ? 1.2 : 1)
            radius: 5
            border.width: 2
            border.color: delegate.isBestPrice || delegate.highlighted ? '#00BCFF' : '#262626'
            Label {
                anchors.right: background.right
                anchors.rightMargin: 20
                anchors.verticalCenter: background.top
                color: '#000000'
                font.pixelSize: 10
                font.weight: 600
                text: 'Best price'
                visible: delegate.isBestPrice
                leftPadding: 6
                rightPadding: 6
                topPadding: 3
                bottomPadding: 3
                background: Rectangle {
                    radius: 8
                    color: '#00BCFF'
                }
            }
        }
        contentItem: RowLayout {
            spacing: 0
            ProviderIcon {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                Layout.rightMargin: 10
                providerName: delegate.quote.serviceProvider
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2
                Label {
                    Layout.fillWidth: true
                    color: '#FFFFFF'
                    font.pixelSize: 14
                    font.weight: 500
                    text: delegate.quote.serviceProvider
                }
                Label {
                    Layout.fillWidth: true
                    visible: {
                        const provider = delegate.quote.serviceProvider
                        const recentlyUsed = self.quoteService.recentlyUsedProviders
                        return recentlyUsed.includes(provider)
                    }
                    color: '#A0A0A0'
                    font.pixelSize: 11
                    font.weight: 400
                    text: 'Recently used'
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                spacing: 4
                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Label.AlignRight
                    color: '#FFFFFF'
                    font.pixelSize: 12
                    text: {
                        const btcAmount = delegate.quote.destinationAmount
                        if (btcAmount > 0) {
                            let formatted = btcAmount.toFixed(8)
                            formatted = formatted.replace(/\.?0+$/, '')
                            return formatted + ' BTC'
                        }
                        return ''
                    }
                }
                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Label.AlignRight
                    color: '#A0A0A0'
                    font.pixelSize: 12
                    font.weight: 500
                    text: 'You receive'
                }
            }
            Image {
                Layout.leftMargin: 10
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/check.svg'
                visible: delegate.isSelected
            }
        }
        onClicked: self.quoteClicked(delegate.quote)
    }
}

