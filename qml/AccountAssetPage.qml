import Blockstream.Green
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    signal sendClicked()
    signal receiveClicked()
    signal transactionClicked(Transaction transaction)
    required property Context context
    required property Asset asset
    required property Account account

    id: self
    title: UtilJS.accountName(self.account)
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    bottomPadding: 0
    footer: null
    contentItem: TListView {
        id: list_view
        spacing: 8
        header: ColumnLayout {
            onHeightChanged: list_view.contentY = -(list_view.headerItem?.height ?? 0)
            width: list_view.width
            spacing: 0
            AssetIcon {
                Layout.alignment: Qt.AlignCenter
                asset: self.asset
                size: 48
            }
            Convert {
                id: convert
                account: self.account
                asset: self.asset
                input: ({ satoshi: self.account.json.satoshi[self.asset.id] })
                unit: UtilJS.unit(self.context)
            }
            Label {
                Layout.topMargin: 12
                Layout.alignment: Qt.AlignCenter
                color: '#FAFAFA'
                font.pixelSize: 24
                font.weight: 500
                text: convert.output.label
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                color: '#A0A0A0'
                font.pixelSize: 14
                font.weight: 400
                text: convert.fiat.label
                visible: convert.fiat.available
            }
            RowLayout {
                Layout.bottomMargin: 12
                Layout.topMargin: 12
                spacing: 8
                visible: !self.account.hidden
                ActionButton {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    icon.source: 'qrc:/svg/send-white.svg'
                    text: qsTrId('id_send')
                    onClicked: self.sendClicked()
                }
                ActionButton {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    icon.source: 'qrc:/svg/receive-white.svg'
                    text: qsTrId('id_receive')
                    onClicked: self.receiveClicked()
                }
            }
            FieldTitle {
                Layout.bottomMargin: 12
                text: qsTrId('id_transactions')
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                color: '#929292'
                font.pixelSize: 14
                text: `You don't have any transactions yet.`
                visible: list_view.count === 0
                wrapMode: Label.Wrap
            }
        }
        model: TransactionModel {
            id: model
            context: self.context
            Component.onCompleted: {
                model.updateFilterAccounts(self.account, true)
                model.updateFilterAssets(self.asset, true)
            }
        }
        delegate: HomePage.TransactionDelegate2 {
            id: delegate
            onClicked: self.transactionClicked(delegate.transaction)
        }
        footer: Item {
            implicitHeight: 0
        }
    }

    component ActionButton: AbstractButton {
        id: button
        padding: 20
        background: Rectangle {
            color: Qt.lighter('#181818', button.hovered ? 1.1 : 1)
            border.color: Qt.lighter('#262626', button.hovered ? 1.1 : 1)
            border.width: 1
            radius: 4
        }
        contentItem: ColumnLayout {
            spacing: 10
            Image {
                Layout.alignment: Qt.AlignCenter
                id: image
                source: button.icon.source
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                font.pixelSize: 14
                font.weight: 400
                color: '#FAFAFA'
                opacity: button.enabled ? 1.0 : 0.6
                text: button.text
            }
        }
    }
}
