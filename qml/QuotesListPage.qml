import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    id: quotes_page
    required property var quotes
    required property var quoteService
    title: 'Change Exchange'
    property var originalSelectedQuote: null
    property bool isSaving: false
    Component.onCompleted: {
        quotes_page.originalSelectedQuote = quotes_page.quoteService.selectedQuote
    }
    StackView.onDeactivated: {
        if (!quotes_page.isSaving && quotes_page.originalSelectedQuote) {
            quotes_page.quoteService.setSelectedQuote(quotes_page.originalSelectedQuote)
        }
    }
    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 50 
        spacing: 8
        ListView {
            id: quotes_list_view
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: quotes_page.quotes || []
            spacing: 8
            delegate: ItemDelegate {
                id: quote_delegate
                width: ListView.view.width
                height: 60
                property bool isFirst: index === 0
                property bool isSelected: {
                    if (!modelData || !quotes_page.quoteService.selectedQuote) return false
                    const selected = quotes_page.quoteService.selectedQuote
                    return modelData.serviceProvider === selected.serviceProvider &&
                           Math.abs((modelData.destinationAmount || 0) - (selected.destinationAmount || 0)) < 0.00000001
                }
                highlighted: quote_delegate.isSelected
                background: Rectangle {
                    color: Qt.lighter('#181818', quote_delegate.hovered ? 1.2 : 1)
                    radius: 5
                    border.width: 1
                    border.color: quote_delegate.highlighted ? '#00BCFF' : '#262626'
                }
                Rectangle {
                    id: best_price_badge
                    visible: quote_delegate.isFirst
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.top: parent.top
                    anchors.topMargin: -8
                    width: best_price_label.contentWidth + 12
                    height: best_price_label.contentHeight + 6
                    radius: 8
                    color: '#00BCFF'
                    Label {
                        id: best_price_label
                        anchors.centerIn: parent
                        font.pixelSize: 10
                        font.weight: 600
                        text: 'Best price'
                    }
                }
                contentItem: RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    anchors.topMargin: 10
                    anchors.bottomMargin: 10
                    spacing: 10
                    ProviderIcon {
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20
                        Layout.alignment: Qt.AlignVCenter
                        providerName: modelData ? (modelData.serviceProvider || '') : ''
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        color: '#FFFFFF'
                        font.pixelSize: 14
                        font.weight: 500
                        text: modelData ? (modelData.serviceProvider || '') : ''
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
                                if (!modelData) return ''
                                const btcAmount = modelData.destinationAmount || 0
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
                }
                onClicked: {
                    if (modelData) {
                        quotes_page.quoteService.setSelectedQuote(modelData)
                    }
                }
            }
        }
        Item { Layout.fillHeight: true }
        PrimaryButton {
            Layout.fillWidth: true
            text: 'Save'
            onClicked: {
                quotes_page.isSaving = true
                quotes_page.StackView.view.pop()
            }
        }
    }
    footerItem: null
}

