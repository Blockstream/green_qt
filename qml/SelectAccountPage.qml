import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    signal selected(account: Account, asset: Asset)
    required property Context context
    required property Account account
    required property Asset asset
    id: self
    title: qsTrId('Choose Asset')
    contentItem: ColumnLayout {
        spacing: 5
        SearchField {
            Layout.fillWidth: true
            id: search_field
        }
        FieldTitle {
            Layout.topMargin: 25
            text: {
                if (search_field.text.trim().length === 0) return 'Other Assets'
                if (list_view.count === 0) return 'No search results'
                return 'Search results'
            }
        }
        TListView {
            id: list_view
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: -1
            model: {
                const deployment = self.context.deployment
                const assets = new Set()
                const search = search_field.text.trim().toLowerCase()
                for (let i = 0; i < self.context.accounts.length; i++) {
                    const account = self.context.accounts[i]
                    for (const [id, satoshi] of Object.entries(account.json.satoshi)) {
                        if (satoshi === 0) continue
                        const asset = AssetManager.assetWithId(deployment, id)
                        if (search) {
                            const term = asset.name ? asset.name.toLowerCase() : asset.id
                            if (term.indexOf(search) < 0) continue
                        }
                        assets.add(asset)
                    }
                }
                return [...assets].sort((a, b) => {
                    if (a.weight > b.weight) return -1
                    if (b.weight > a.weight) return 1
                    if (b.weight === 0) {
                        if (a.icon && !b.icon) return -1
                        if (!a.icon && b.icon) return 1
                        if (Object.keys(a.data).length > 0 && Object.keys(b.data).length === 0) return -1
                        if (Object.keys(a.data).length === 0 && Object.keys(b.data).length > 0) return 1
                    }
                    return a.name.localeCompare(b.name)
                })
            }

            spacing: 4
            delegate: ItemDelegate {
                required property var modelData
                required property int index
                property Asset asset: modelData
                id: delegate
                width: ListView.view.width
                enabled: accounts_repeater.count > 0
                padding: 0
                topPadding: 0
                bottomPadding: 0
                topInset: 0
                bottomInset: 0
                background: Rectangle {
                    radius: 4
                    color: Qt.lighter('#2F2F35', !delegate.highlighted && delegate.hovered ? 1.2 : 1)
                    border.width: delegate.ListView.isCurrentItem ? 2 : 0
                    border.color: '#00BCFF'
                }
                contentItem: ColumnLayout {
                    spacing: 0
                    AbstractButton {
                        Layout.fillWidth: true
                        background: null
                        padding: 10
                        contentItem: RowLayout {
                            spacing: 10
                            Image {
                                Layout.alignment: Qt.AlignCenter
                                Layout.maximumWidth: 32
                                Layout.maximumHeight: 32
                                source: UtilJS.iconFor(delegate.asset)
                            }
                            Label {
                                Layout.fillWidth: true
                                font.pixelSize: 14
                                font.weight: 500
                                opacity: delegate.asset.name ? 1 : 0.6
                                text: delegate.asset.name || delegate.asset.id
                                elide: Label.ElideMiddle
                            }
                        }
                        onClicked: list_view.currentIndex = delegate.ListView.isCurrentItem ? -1 : delegate.index
                    }
                    Collapsible {
                        Layout.fillWidth: true
                        collapsed: !delegate.ListView.isCurrentItem
                        contentWidth: width
                        contentHeight: collapsible_layout.height
                        ColumnLayout {
                            id: collapsible_layout
                            width: parent.width
                            spacing: 0
                            Pane {
                                Layout.fillWidth: true
                                padding: 10
                                visible: delegate.asset.amp
                                background: Rectangle {
                                    color: '#00BCFF'
                                    opacity: 0.2
                                }
                                contentItem: RowLayout {
                                    spacing: 10
                                    Image {
                                        Layout.alignment: Qt.AlignCenter
                                        source: 'qrc:/svg2/shield_warning.svg'
                                    }
                                    Label {
                                        Layout.preferredWidth: 0
                                        Layout.fillWidth: true
                                        color: '#00BCFF'
                                        font.pixelSize: 12
                                        font.weight: 600
                                        text: `${delegate.asset.name} is an AMP asset. You need an AMP account in order to receive it.`
                                        wrapMode: Label.WordWrap
                                    }
                                }
                            }
                            Rectangle {
                                width: parent.width
                                height: 2
                                color: delegate.ListView.isCurrentItem ? '#00BCFF' : 'transparent'
                            }
                            Repeater {
                                id: accounts_repeater
                                model: {
                                    const accounts = []
                                    for (let i = 0; i < self.context.accounts.length; i++) {
                                        const account = self.context.accounts[i]
                                        if (account.hidden) continue
                                        const satoshi = String(account.json.satoshi[delegate.asset.id])
                                        if (satoshi > 0) accounts.push({ account, satoshi })
                                    }
                                    return accounts
                                }
                                delegate: SelectAccountButton {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    id: button
                                    asset: delegate.asset
                                    account: button.modelData.account
                                    satoshi: button.modelData.satoshi
                                    onSelected: (account, asset) => self.selected(account, asset)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component SelectAccountButton: AbstractButton {
        signal selected(Account account, Asset asset)
        required property Account account
        required property Asset asset
        required property string satoshi
        onClicked: button.selected(button.account, button.asset)
        id: button
        background: Item {
            Rectangle {
                color: '#FFF'
                opacity: 0.2
                width: parent.width
                height: 1
                anchors.bottom: parent.bottom
            }
            Rectangle {
                border.width: 2
                border.color: '#00BCFF'
                color: 'transparent'
                radius: 4
                anchors.fill: parent
                anchors.margins: -4
                z: -1
                opacity: button.visualFocus ? 1 : 0
            }
        }
        padding: 10
        contentItem: RowLayout {
            ColumnLayout {
                Label {
                    Layout.fillWidth: true
                    font.pixelSize: 14
                    font.weight: 500
                    text: UtilJS.accountName(button.account)
                    wrapMode: Label.Wrap
                }
                Label {
                    font.pixelSize: 11
                    font.weight: 400
                    opacity: 0.4
                    text: UtilJS.networkLabel(button.account.network) + ' / ' + UtilJS.accountLabel(button.account)
                }
            }
            Convert {
                id: convert
                account: button.account
                asset: button.asset
                input: ({ satoshi: button.satoshi })
                unit: button.account.session.unit
            }
            ColumnLayout {
                Label {
                    Layout.alignment: Qt.AlignRight
                    font.pixelSize: 14
                    font.weight: 500
                    text: convert.output.label
                    wrapMode: Label.Wrap
                }
                Label {
                    Layout.alignment: Qt.AlignRight
                    font.pixelSize: 11
                    font.weight: 400
                    opacity: 0.4
                    text: convert.fiat.label
                    visible: convert.fiat.available
                }
            }
            HSpacer {
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/next_arrow.svg'
            }
        }
    }
}

