import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

WalletHeaderCard {
    readonly property var assets: {
        const context = self.context
        const assets = new Set
        if (context) {
            for (let i = 0; i < context.accounts.length; i++) {
                const account = context.accounts[i]
                for (let j = 0; j < account.balances.length; j++) {
                    const balance = account.balances[j]
                    if (balance.amount === 0) continue
                    if (balance.asset.icon) {
                        assets.add(balance.asset)
                    }
                }
            }
        }
        return [...assets]
    }
    readonly property bool withoutIcon: {
        const context = self.context
        if (context) {
            for (let i = 0; i < context.accounts.length; i++) {
                const account = context.accounts[i]
                for (let j = 0; j < account.balances.length; j++) {
                    const balance = account.balances[j]
                    if (balance.amount === 0) continue
                    if (!balance.asset.icon) return true
                }
            }
        }
        return false
    }
    id: self
    visible: self.assets.length > 0
    headerItem: RowLayout {
        Image {
            Layout.alignment: Qt.AlignCenter
            opacity: 0.6
            source: 'qrc:/svg2/star.svg'
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            font.capitalization: Font.AllUppercase
            font.pixelSize: 12
            font.weight: 400
            opacity: 0.6
            text: qsTrId('id_assets')
        }
        HSpacer {
            Layout.minimumHeight: 28
        }
    }
    contentItem: ColumnLayout {
        RowLayout {
            Layout.fillHeight: false
            spacing: -12
            AssetIcon {
                visible: self.withoutIcon
            }
            Repeater {
                model: self.assets
                AssetIcon {
                    asset: modelData
                }
            }
        }
        VSpacer {
        }
    }
}
