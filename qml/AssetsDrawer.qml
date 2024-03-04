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
        const assets = new Map
        for (let i = 0; i < context.accounts.length; i++) {
            const account = context.accounts[i]
            for (let asset_id in account.json.satoshi) {
                const satoshi = account.json.satoshi[asset_id]
                if (satoshi === 0) continue
                const asset = context.getOrCreateAsset(asset_id)
                let sum = assets.get(asset)
                if (sum) {
                    sum.satoshi += satoshi
                } else {
                    sum = { satoshi, asset }
                    assets.set(asset, sum)
                }
            }
        }
        return [...assets.values()].sort((a, b) => {
            if (a.asset.weight > b.asset.weight) return -1
            if (b.asset.weight > a.asset.weight) return 1
            if (b.asset.weight === 0) {
                if (a.asset.icon && !b.asset.icon) return -1
                if (!a.asset.icon && b.asset.icon) return 1
                if (Object.keys(a.asset.data).length > 0 && Object.keys(b.asset.data).length === 0) return -1
                if (Object.keys(a.asset.data).length === 0 && Object.keys(b.asset.data).length > 0) return 1
            }
            return a.asset.name.localeCompare(b.asset.name)
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
                            satoshi: delegate.modelData.satoshi
                        }
                    }
                }
            }
        }
    }
    Component {
        id: asset_details_page
        AssetDetailsPage {
            closeAction: Action {
                onTriggered: self.close()
            }
            onAccountClicked: (account) => {
                self.close()
                self.accountClicked(account)
            }
        }
    }
    component AssetButton: AbstractButton {
        required property Asset asset
        required property var satoshi
        Convert {
            id: convert
            context: self.context
            asset: button.asset
            input: ({ satoshi: button.satoshi })
            unit: self.context.primarySession.unit
        }
        Layout.fillWidth: true
        onClicked: stack_view.push(asset_details_page, { context: self.context, asset: button.asset })
        id: button
        enabled: button.asset.hasData
        leftPadding: 20
        rightPadding: 20
        topPadding: 15
        bottomPadding: 15
        background: Rectangle {
            color: Qt.lighter('#222226', button.enabled && button.hovered ? 1.2 : 1)
            radius: 5
        }
        contentItem: RowLayout {
            spacing: 10
            AssetIcon {
                asset: button.asset
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                color: button.asset.name ? '#FFF' : '#929292'
                font.pixelSize: 14
                font.weight: 600
                text: button.asset.name || button.asset.id
                elide: Label.ElideRight
            }
            ColumnLayout {
                Label {
                    Layout.alignment: Qt.AlignRight
                    color: '#FFF'
                    font.pixelSize: 14
                    font.weight: 600
                    text: convert.output.label
                }
                Label {
                    Layout.alignment: Qt.AlignRight
                    color: '#929292'
                    font.pixelSize: 12
                    font.weight: 400
                    text: convert.fiat.label
                    visible: convert.fiat.available
                }
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                Layout.leftMargin: 10
                source: 'qrc:/svg2/right.svg'
                visible: button.enabled ? 1 : 0
            }
        }
    }
}
