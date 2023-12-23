import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

WalletDrawer {
    signal accountClicked(Account account)
    readonly property var assets: {
        const context = self.context
        if (!context) return []
        const deployment = context.deployment
        const assets = new Map
        for (let i = 0; i < context.accounts.length; i++) {
            const account = context.accounts[i]
            if (account.network.liquid) {
                for (let asset_id in account.json.satoshi) {
                    const satoshi = account.json.satoshi[asset_id]
                    const asset = AssetManager.assetWithId(deployment, asset_id)
                    let sum = assets.get(asset)
                    if (sum) {
                        sum.satoshi += satoshi
                    } else {
                        sum = { satoshi, asset }
                        assets.set(asset, sum)
                    }
                }
            }
        }
        return [...assets.values()].sort((a, b) => {
            if (a.asset.data.name === 'btc') return -1
            if (b.asset.data.name === 'btc') return 1
            if (a.asset.icon && !b.asset.icon) return -1
            if (!a.asset.icon && b.asset.icon) return 1
            if (a.asset.name && !b.asset.name) return -1
            if (!a.asset.name && b.asset.name) return 1
            return a.asset.id.localeCompare(b.asset.id)
        })
    }
    id: self
    contentItem: GStackView {
        id: stack_view
        initialItem: StackViewPage {
            title: qsTrId('id_assets')
            rightItem: CloseButton {
                onClicked: self.close()
            }
            contentItem: Flickable {
                ScrollIndicator.vertical: ScrollIndicator {
                }
                id: flickable
                clip: true
                contentWidth: flickable.width
                contentHeight: layout.height
                ColumnLayout {
                    id: layout
                    width: flickable.width
                    spacing: 5
                    Repeater {
                        model: self.assets
                        delegate: AssetButton {
                            required property var modelData
                            id: delegate
                            asset: delegate.modelData.asset
                            satoshi: String(delegate.modelData.satoshi)
                        }
                    }
                }
            }
        }
    }
    Component {
        id: asset_details_page
        AssetDetailsPage {
            onAccountClicked: (account) => {
                self.close()
                self.accountClicked(account)
            }
        }
    }
    component AssetButton: AbstractButton {
        required property Asset asset
        required property string satoshi
        Convert {
            id: convert
            context: self.context
            asset: button.asset
            value: button.satoshi
            unit: 'sats'
        }
        Layout.fillWidth: true
        onClicked: stack_view.push(asset_details_page, { context: self.context, asset: button.asset })
        id: button
        enabled: button.asset.hasData
        padding: 20
        background: Rectangle {
            color: Qt.lighter('#222226', button.enabled && button.hovered ? 1.2 : 1)
            radius: 5
        }
        contentItem: RowLayout {
            spacing: 20
            AssetIcon {
                asset: button.asset
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                color: '#FFF'
                font.pixelSize: 14
                font.weight: 400
                text: asset.name
                wrapMode: Label.Wrap
            }
            ColumnLayout {
                Label {
                    Layout.alignment: Qt.AlignRight
                    color: '#FFF'
                    font.pixelSize: 14
                    font.weight: 600
                    text: convert.unitLabel
                }
                Label {
                    Layout.alignment: Qt.AlignRight
                    color: '#929292'
                    font.pixelSize: 12
                    font.weight: 400
                    text: convert.fiatLabel
                    visible: convert.result.fiat_currency ?? false
                }
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/right.svg'
                opacity: button.enabled ? 1 : 0
            }
        }
    }
}
