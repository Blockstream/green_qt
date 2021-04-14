import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3

Pane {
    id: self
    Layout.fillWidth: true
    Layout.fillHeight: true
    property bool showAllAssets: false
    background: null
    padding: 0
    contentItem: ColumnLayout {
        Layout.fillWidth: true
        spacing: 8
        LiquidHeader {
            visible: account_view.account.wallet.network.liquid
        }
        Label {
            text: qsTrId('id_transactions')
            Layout.fillWidth: true
            font.pixelSize: 18
            font.styleName: 'Medium'
        }
        TransactionListView {
            id: transaction_list_view
            interactive: false
            Layout.fillWidth: true
            Layout.fillHeight: true
            height: contentHeight
            account: account_view.account
            onClicked: navigation.go(`/${wallet.network.id}/${wallet.id}/${account_view.account.json.pointer}/${transaction.data.txhash}`)
        }
    }

    component LiquidHeader: ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        AccountIdBadge {
            visible: account_view.account.json.type === '2of2_no_recovery'
            account: account_view.account
            Layout.fillWidth: true
        }
        Label {
            text: qsTrId('id_assets')
            Layout.fillWidth: true
            font.pixelSize: 18
            font.styleName: 'Medium'
        }
        Repeater {
            model: {
                const balances = []
                for (let i = 0; i < account_view.account.balances.length; ++i) {
                    if (!self.showAllAssets && i === 3) break
                    balances.push(account_view.account.balances[i])
                }
                return balances
            }
            ItemDelegate {
                topPadding: 8
                bottomPadding: 8
                leftPadding: 16
                rightPadding: 16
                background: Rectangle {
                    color: constants.c700
                    radius: 8
                }
                Layout.fillWidth: true
                contentItem: RowLayout {
                    spacing: 16
                    AssetIcon {
                        asset: modelData.asset
                    }
                    Label {
                        Layout.fillWidth: true
                        text: modelData.asset.name
                        font.pixelSize: 16
                        elide: Label.ElideRight
                        font.styleName: 'Regular'
                    }
                    Label {
                        text: modelData.displayAmount
                        font.pixelSize: 14
                        font.styleName: 'Regular'
                    }
                }
                onClicked: navigation.go(`/${wallet.network.id}/${wallet.id}/${account_view.account.json.pointer}/${modelData.asset.id}`)
            }
        }
        GButton {
            enabled: account_view.account.balances.length > 3
            text: {
                const count = account_view.account.balances.length
                if (count <= 3) return qsTrId('id_no_more_assets')
                if (self.showAllAssets) return qsTrId('id_hide_assets')
                return qsTrId('id_show_all_assets')
            }
            Layout.alignment: Qt.AlignCenter
            onClicked: self.showAllAssets = !self.showAllAssets
        }
    }
}
