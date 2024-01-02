import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    required property Context context
    required property Account account
    required property Asset asset
    property bool showCreateAccount: false
    property bool filterEmpty: false

    signal selected(account: Account, asset: Asset)
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
            model: AssetsModel {
                filter: search_field.text.trim()
                deployment: context.deployment
                minWeight: 1
            }
            spacing: 4
            delegate: ItemDelegate {
                required property Asset asset
                required property int index
                id: delegate
                width: ListView.view.width
                enabled: accounts_repeater.count > 0 || self.showCreateAccount
                padding: 0
                topPadding: 0
                bottomPadding: 0
                topInset: 0
                bottomInset: 0
                background: Rectangle {
                    radius: 4
                    color: '#2F2F35'
                    border.width: delegate.ListView.isCurrentItem ? 2 : 0
                    border.color: '#00B45A'
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
                                text: delegate.asset.name
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
                                    color: '#00B45A'
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
                                        color: '#00B45A'
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
                                color: delegate.ListView.isCurrentItem ? '#00B45A' : 'transparent'
                            }
                            Label {
                                visible: false
                                Layout.fillWidth: true
                                wrapMode: Label.WordWrap
                                text: JSON.stringify(delegate.asset.data, null, '  ')
                            }
                            Repeater {
                                id: accounts_repeater
                                model: {
                                    const accounts = []
                                    for (let i = 0; i < self.context.accounts.length; i++) {
                                        const account = self.context.accounts[i]
                                        if (account.hidden) continue
                                        if (account.network.key !== delegate.asset.networkKey) continue
                                        const key = account.network.liquid ? delegate.asset.id : 'btc'
                                        const satoshi = account.json.satoshi[key]
                                        if (!self.filterEmpty || satoshi > 0) accounts.push({ account, satoshi })
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
                            CreateAccountButton {
                                Layout.fillWidth: true
                                visible: self.showCreateAccount
                                onClicked: {
                                    self.StackView.view.push(create_account_page, {
                                        asset: delegate.asset,
                                    })
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
        required property var satoshi
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
                border.color: '#00B45A'
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
                value: button.satoshi ?? '0'
                unit: 'sats'
            }
            ColumnLayout {
                Label {
                    Layout.alignment: Qt.AlignRight
                    font.pixelSize: 14
                    font.weight: 500
                    text: convert.unitLabel
                    wrapMode: Label.Wrap
                }
                Label {
                    Layout.alignment: Qt.AlignRight
                    font.pixelSize: 11
                    font.weight: 400
                    opacity: 0.4
                    text: convert.fiatLabel
                    visible: convert.fiat
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

    component CreateAccountButton: AbstractButton {
        background: null
        padding: 10
        contentItem: RowLayout {
            Label {
                Layout.alignment: Qt.AlignCenter
                font.pixelSize: 14
                font.weight: 500
                text: qsTrId('id_create_new_account')
            }
            HSpacer {
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/next_arrow.svg'
            }
        }
    }

    Component {
        id: create_account_page
        CreateAccountPage {
            id: page
            context: self.context
            editableAsset: false
            onCreated: (account) => self.selected(account, page.asset)
        }
    }
}
