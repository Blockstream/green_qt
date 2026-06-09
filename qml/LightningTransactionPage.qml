import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    required property LightningTransaction transaction
    required property Context context

    readonly property Asset asset: self.context.getOrCreateAsset('lnbtc')
    readonly property double amount: self.transaction.data.satoshi['lnbtc'] ?? 0
    readonly property double fee: self.transaction.data.fee ?? 0
    readonly property bool isOutgoing: self.transaction.data.type === 'outgoing'
    readonly property double displayAmount: self.amount + (self.isOutgoing ? self.fee : 0)
    readonly property string note: self.transaction.data.description?.trim() ?? ''
    readonly property bool hasDetails: self.note !== '' || self.isOutgoing

    id: self
    title: qsTrId('id_transaction_details')
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    footerItem: AbstractButton {
        Layout.fillWidth: true
        id: details_button
        leftPadding: 4
        rightPadding: 4
        topPadding: 8
        bottomPadding: 8
        background: Rectangle {
            color: Qt.alpha('#FFF', details_button.hovered ? 0.05 : 0)
        }
        contentItem: RowLayout {
            Image {
                source: 'qrc:/svg3/magnifying-glass.svg'
            }
            Label {
                Layout.fillWidth: true
                color: '#00BCFF'
                text: qsTrId('id_details')
            }
        }
        onClicked: self.pushPage(details_page, { transaction: self.transaction })
    }
    contentItem: VFlickable {
        alignment: Qt.AlignTop
        spacing: 10
        TransactionIcon {
            assets: [{ asset: self.asset }]
            transactionType: self.transaction.data.type
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            font.pixelSize: 20
            font.weight: 600
            text: 'Lightning Transaction'
        }
        InlineCopyableLabel {
            Layout.alignment: Qt.AlignCenter
            font.pixelSize: 14
            font.weight: 400
            color: '#929292'
            text: UtilJS.formatTransactionTimestamp(self.transaction, locale)
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            topPadding: 3
            bottomPadding: 3
            leftPadding: 8
            rightPadding: 8
            color: '#000000'
            font.pixelSize: 14
            font.weight: 700
            text: UtilJS.transactionTypeLabel(self.transaction)
            background: Rectangle {
                color: '#00BCFF'
                radius: height / 2
            }
        }
        Convert {
            id: convert
            context: self.context
            asset: self.asset
            input: ({ satoshi: self.displayAmount })
            unit: UtilJS.unit(self.context)
        }
        InlineCopyableLabel {
            Layout.alignment: Qt.AlignCenter
            font.family: 'Roboto Mono'
            font.features: { 'calt': 0, 'zero': 1 }
            font.pixelSize: 24
            font.weight: 500
            text: UtilJS.incognito(Settings.incognito, convert.output.label)
        }
        InlineCopyableLabel {
            Layout.alignment: Qt.AlignCenter
            font.family: 'Roboto Mono'
            font.features: { 'calt': 0, 'zero': 1 }
            font.pixelSize: 14
            font.weight: 400
            opacity: 0.6
            text: UtilJS.incognito(Settings.incognito, convert.fiat.label)
            visible: convert.fiat.available
        }
        LineSeparator {
            Layout.bottomMargin: 10
            Layout.topMargin: 10
            visible: self.hasDetails
        }
        GridLayout {
            rowSpacing: 10
            columnSpacing: 20
            columns: 2
            visible: self.hasDetails
            Label {
                Layout.minimumWidth: 100
                Layout.alignment: Qt.AlignTop
                color: '#929292'
                font.pixelSize: 14
                font.weight: 400
                text: qsTrId('id_note')
                visible: self.note !== ''
            }
            InlineCopyableLabel {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                color: '#FFF'
                font.pixelSize: 14
                font.weight: 400
                horizontalAlignment: Text.AlignRight
                text: self.note
                visible: self.note !== ''
                wrapMode: Label.WordWrap
            }
            Label {
                Layout.minimumWidth: 100
                color: '#929292'
                font.pixelSize: 14
                font.weight: 400
                text: qsTrId('id_network_fee')
                visible: self.isOutgoing
            }
            Convert {
                id: fee_convert
                context: self.context
                asset: self.asset
                input: ({ satoshi: self.fee })
                unit: UtilJS.unit(self.context)
            }
            RowLayout {
                spacing: 4
                visible: self.isOutgoing
                HSpacer {
                }
                InlineCopyableLabel {
                    Layout.alignment: Qt.AlignRight
                    topPadding: 4
                    bottomPadding: 4
                    color: '#FFF'
                    font.pixelSize: 14
                    font.weight: 400
                    text: UtilJS.incognito(Settings.incognito, fee_convert.output.label)
                }
                InlineCopyableLabel {
                    Layout.alignment: Qt.AlignRight
                    topPadding: 4
                    bottomPadding: 4
                    color: '#FFF'
                    font.pixelSize: 14
                    font.weight: 400
                    opacity: 0.6
                    text: UtilJS.incognito(Settings.incognito, '~ ' + fee_convert.fiat.label)
                    visible: fee_convert.fiat.available
                }
            }
        }
        LineSeparator {
            Layout.bottomMargin: 10
            Layout.topMargin: 10
            visible: self.isOutgoing
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 20
            visible: self.isOutgoing
            Label {
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true
                Layout.minimumWidth: 100
                color: '#FFF'
                font.pixelSize: 14
                font.weight: 600
                text: qsTrId('id_total_spent')
            }
            Convert {
                id: total_convert
                context: self.context
                asset: self.asset
                input: ({ satoshi: Math.abs(self.amount) })
                unit: UtilJS.unit(self.context)
            }
            ColumnLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 4
                InlineCopyableLabel {
                    Layout.alignment: Qt.AlignRight
                    copyText: total_convert.output.label
                    font.pixelSize: 14
                    font.weight: 600
                    text: UtilJS.incognito(Settings.incognito, total_convert.output.label)
                }
                InlineCopyableLabel {
                    Layout.alignment: Qt.AlignRight
                    font.pixelSize: 14
                    font.weight: 400
                    opacity: 0.6
                    text: UtilJS.incognito(Settings.incognito, '~ ' + total_convert.fiat.label)
                    visible: total_convert.fiat.available
                }
            }
        }
        VSpacer {
        }
    }

    component LineSeparator: Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        height: 1
        color: '#404040'
    }

    Component {
        id: details_page
        LightningTransactionDetailsPage {
            onCloseClicked: self.closeClicked()
        }
    }
}
