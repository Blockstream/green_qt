import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

WalletDrawer {
    id: self
    width: 500
    contentItem: Page {
        background: null
        header: Pane {
            background: null
            padding: 0
            bottomPadding: 20
            contentItem: RowLayout {
                DrawerTitle {
                    text: qsTrId('id_assets')
                }
                HSpacer {
                }
                CloseButton {
                    onClicked: self.close()
                }
            }
        }
        contentItem: ColumnLayout {
            spacing: 4
            Repeater {
                model: {
                    const context = self.context
                    const assets = new Map
                    if (context) {
                        for (let i = 0; i < context.accounts.length; i++) {
                            const account = context.accounts[i]
                            for (let j = 0; j < account.balances.length; j++) {
                                const balance = account.balances[j]
                                const asset = balance.asset
                                if (asset.icon) {
                                    let sum = assets.get(asset)
                                    if (sum) {
                                        sum.amount += balance.amount
                                    } else {
                                        sum = { amount: balance.amount, asset }
                                        assets.set(asset, sum)
                                    }
                                }
                            }
                        }
                    }
                    console.log(assets.values())
                    return [...assets.values()]
                }
                delegate: ItemDelegate {
                    Layout.fillWidth: true
                    padding: 10
                    background: Rectangle {
                        radius: 4
                        color: '#222226'
                    }
                    contentItem: RowLayout {
                        spacing: 10
                        AssetIcon {
                            asset: modelData.asset
                        }
                        Label {
                            font.family: 'SF Compact Display'
                            font.pixelSize: 13
                            font.weight: 500
                            text: modelData.asset.name
                            elide: Label.ElideRight
                        }
                        HSpacer {
                        }
                        ColumnLayout {
                            Layout.fillWidth: false
                            Layout.fillHeight: false
                            Layout.alignment: Qt.AlignCenter
                            Label {
                                Layout.alignment: Qt.AlignRight
                                font.capitalization: Font.AllUppercase
                                font.family: 'SF Compact Display'
                                font.pixelSize: 13
                                font.weight: 500
                                text: modelData.asset.formatAmount(modelData.amount, true)
                            }
                            Label {
                                Layout.alignment: Qt.AlignRight
                                font.family: 'SF Compact Display'
                                font.pixelSize: 12
                                font.weight: 400
                                opacity: 0.6
                                text: '-'
                            }
                        }
                    }
                }
            }
            VSpacer {
            }
        }
    }
}
