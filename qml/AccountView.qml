import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.14
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

StackView {
    id: account_view
    required property Account account

    function getUnblindingData(tx) {
        return {
            version: 0,
            txid: tx.txhash,
            type: tx.type,
            inputs: tx.inputs
                .filter(i => i.asset_id && i.satoshi && i.assetblinder && i.amountblinder)
                .map(i => ({
                   vin: i.pt_idx,
                   asset_id: i.asset_id,
                   assetblinder: i.assetblinder,
                   satoshi: i.satoshi,
                   amountblinder: i.amountblinder,
                })),
            outputs: tx.outputs
                .filter(o => o.asset_id && o.satoshi && o.assetblinder && o.amountblinder)
                .map(o => ({
                   vout: o.pt_idx,
                   asset_id: o.asset_id,
                   assetblinder: o.assetblinder,
                   satoshi: o.satoshi,
                   amountblinder: o.amountblinder,
                })),
        }
    }

    function copyUnblindingData(item, tx) {
        Clipboard.copy(JSON.stringify(getUnblindingData(tx), null, '  '))
        item.ToolTip.show(qsTrId('id_copied_to_clipboard'), 2000);
    }

    initialItem: TransactionListView {
        id: transaction_list_view
        account: account_view.account
        onClicked: account_view.push(transaction_view_component, { transaction })
        header: Loader {
            active: account_view.account.wallet.network.liquid
            sourceComponent: Pane {
                onHeightChanged: transaction_list_view.positionViewAtBeginning()
                width: transaction_list_view.width
                property bool showAllAssets: false
                background: Item {}
                padding: 0
                contentItem: ColumnLayout {
                    spacing: 16
                    AccountIdBadge {
                        visible: account_view.account.json.type === '2of2_no_recovery'
                        account: account_view.account
                        Layout.fillWidth: true
                    }
                    Repeater {
                        model: {
                            const balances = []
                            for (let i = 0; i < account_view.account.balances.length; ++i) {
                                if (!showAllAssets && i === 3) break
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
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Label {
                                        Layout.fillWidth: true
                                        text: modelData.asset.name
                                        font.pixelSize: 16
                                        elide: Label.ElideRight
                                    }
                                    Label {
                                        visible: 'entity' in modelData.asset.data
                                        Layout.fillWidth: true
                                        opacity: 0.5
                                        text: modelData.asset.data.entity ? modelData.asset.data.entity.domain : ''
                                        elide: Label.ElideRight
                                    }
                                }
                                Label {
                                    text: modelData.displayAmount
                                }
                            }
                            onClicked: {
                                account_view.push(asset_view_component, { balance: modelData })
                            }
                        }
                    }
                    Button {
                        enabled: account_view.account.balances.length > 3
                        flat: true
                        text: {
                            const count = account_view.account.balances.length
                            if (count <= 3) return 'No more assets'
                            if (showAllAssets) return `Hide ${account_view.account.balances.length - 3} assets`
                            return `Show remaining ${account_view.account.balances.length - 3} more assets`
                        }
                        Layout.alignment: Qt.AlignCenter
                        onClicked: showAllAssets = !showAllAssets
                    }
                    Label {
                        visible: account_view.account.wallet.network.liquid
                        text: qsTrId('id_transactions')
                        Layout.fillWidth: true
                        font.pixelSize: 16
                        font.styleName: 'Regular'
                    }
                }
            }
        }
    }
    Component {
        id: transaction_view_component
        TransactionView { }
    }
    Component {
        id: asset_view_component
        AssetView { }
    }
}
