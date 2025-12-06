import Blockstream.Green
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    signal accountClicked(Account account)
    required property Context context
    required property Asset asset
    property Account account
    property bool showAllAccounts: true
    property bool sortByBalance: false
    readonly property string ticker: {
        if (!self.asset) return
        return self.asset.data.ticker ?? ''
    }
    readonly property var accounts: {
        const relevant = []
        const other = []
        for (let i = 0; i < self.context.accounts.length; i++) {
            const account = self.context.accounts[i]
            if (account.hidden) continue
            if (account.network.liquid && self.asset.key === 'btc') continue
            if (!account.network.liquid && self.asset.key !== 'btc') continue
            const satoshi = account.json.satoshi[self.asset.id]
            if (self.showAllAccounts || satoshi) {
                relevant.push({ account, satoshi: String(satoshi) })
            } else {
                other.push({ account, satoshi: String(satoshi) })
            }
        }
        const index = (account) => {
            const is_liquid = account.network.liquid
            const is_bitcoin = !is_liquid
            const is_singlesig = account.network.electrum
            const is_multisig = !is_singlesig
            const is_lightning = false
            const is_amp = is_liquid && account.type === "2of2_no_recovery"

            if (is_bitcoin && is_singlesig) return 0
            if (is_bitcoin && is_multisig) return 1
            if (is_lightning) return 2
            if (is_liquid && is_singlesig) return 3
            if (is_liquid && is_multisig && !is_amp) return 4
            if (is_liquid && is_multisig && is_amp) return 5
            return 6
        }
        const weight = (account) => {
            const offset = account.network.mainnet ? 0 : 10
            return offset + index(account)
        }
        relevant.sort((a, b) => {
            if (self.sortByBalance) {
                const as = Number(a.satoshi)
                const bs = Number(b.satoshi)
                if (as > bs) return -1
                if (as < bs) return 1
            }
            const wa = weight(a.account)
            const wb = weight(b.account)
            if (wa < wb) return -1
            if (wa > wb) return 1
            if (a.account.pointer < b.account.pointer) return -1
            if (a.account.pointer > b.account.pointer) return 1
            return 0
        })
        return { relevant, other }
    }
    id: self
    title: qsTrId('id_asset_details')
    rightItem: RowLayout {
        spacing: 20
        ShareButton {
            url: self.asset.url
            visible: self.asset.hasData
        }
        CloseButton {
            onClicked: self.closeClicked()
        }
    }
    contentItem: VFlickable {
        alignment: Qt.AlignTop
        spacing: 5
        AssetIcon {
            Layout.alignment: Qt.AlignCenter
            Layout.bottomMargin: 10
            asset: self.asset
            size: 48
        }
        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            font.pixelSize: 18
            font.weight: 600
            horizontalAlignment: Label.AlignHCenter
            text: self.asset.name
            wrapMode: Label.Wrap
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            text: self.asset.data.entity?.domain ?? ''
            opacity: 0.6
            visible: self.asset.data.entity ?? false
        }
        FieldTitle {
            text: qsTrId('id_accounts')
        }
        Repeater {
            model: self.accounts.relevant
            delegate: AccountButton {
            }
        }
        LinkButton {
            Layout.alignment: Qt.AlignHCenter
            text: qsTrId('id_show_all')
            visible: collapsible.visible && collapsible.collapsed
            onClicked: collapsible.open()
        }
        Collapsible {
            Layout.fillWidth: true
            id: collapsible
            collapsed: self.accounts.relevant.length > 0
            visible: self.accounts.other.length > 0
            ColumnLayout {
                spacing: 5
                width: collapsible.width
                Repeater {
                    model: self.accounts.other
                    delegate: AccountButton {
                    }
                }
            }
        }
        Separator {
            visible: details_grid.visible
        }
        GridLayout {
            id: details_grid
            columns: 2
            visible: self.asset.id !== 'btc'
            Label {
                Layout.minimumWidth: 100
                color: '#929292'
                font.pixelSize: 12
                font.weight: 400
                text: qsTrId('id_ticker')
                visible: self.ticker ?? false
            }
            Label {
                Layout.fillWidth: true
                color: '#FFF'
                font.pixelSize: 12
                font.weight: 400
                text: self.ticker ?? ''
                visible: self.ticker ?? false
            }
            Label {
                color: '#929292'
                font.pixelSize: 12
                font.weight: 400
                text: qsTrId('id_precision')
                visible: self.asset.data.precision >= 0 ?? false
            }
            Label {
                Layout.fillWidth: true
                color: '#FFF'
                font.pixelSize: 12
                font.weight: 400
                text: self.asset.data.precision ?? ''
                visible: self.asset.data.precision >= 0 ?? false
            }
            Label {
                Layout.alignment: Qt.AlignTop
                color: '#929292'
                font.pixelSize: 12
                font.weight: 400
                text: qsTrId('id_asset_id')
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                color: '#FFF'
                font.pixelSize: 12
                font.weight: 400
                text: self.asset.id
                wrapMode: Label.Wrap
            }
        }
        Separator {
            visible: details_grid.visible
        }
        VSpacer {
        }
    }

    component Separator: Rectangle {
        Layout.bottomMargin: 20
        Layout.topMargin: 20
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: '#313131'
    }

    component AccountButton: AbstractButton {
        required property var modelData
        readonly property Account account: button.modelData.account
        readonly property string satoshi: button.modelData.satoshi
        Convert {
            id: convert
            account: button.account
            asset: self.asset
            input: ({ satoshi: button.satoshi })
            unit: button.account.session.unit
        }
        Layout.fillWidth: true
        onClicked: self.accountClicked(button.account)
        id: button
        enabled: button.account != self.account
        padding: 20
        background: Rectangle {
            color: Qt.lighter('#181818', button.account == self.account ? 1.4 : button.hovered ? 1.1 : 1)
            radius: 5
            border.color: '#262626'
            border.width: 1
        }
        contentItem: RowLayout {
            spacing: 20
            ColumnLayout {
                Label {
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: true
                    color: '#FFF'
                    font.pixelSize: 14
                    font.weight: 500
                    text: UtilJS.accountName(button.account)
                }
                Label {
                    font.pixelSize: 12
                    font.weight: 400
                    font.capitalization: Font.AllUppercase
                    color: '#929292'
                    text: UtilJS.networkLabel(button.account.network) + ' / ' + UtilJS.accountLabel(button.account)
                    elide: Label.ElideLeft
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                }
            }
            ColumnLayout {
                Label {
                    Layout.alignment: Qt.AlignRight
                    color: '#FFF'
                    font.pixelSize: 14
                    font.weight: 500
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
            RightArrowIndicator {
                active: button.hovered
            }
        }
    }
}
