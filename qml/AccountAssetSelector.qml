import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

Page {
    required property Context context
    required property Account account
    required property Asset asset
    property bool showCreateAccount: false

    signal canceled()
    signal selected(account: Account, asset: Asset)
    signal create(asset: Asset)

    id: self
    background: null
    header: Pane {
        background: null
        padding: 0
        bottomPadding: 20
        contentItem: RowLayout {
            BackButton {
                Layout.minimumWidth: Math.max(left_item.implicitWidth, right_item.implicitWidth)
                id: left_item
                onClicked: self.canceled()
            }
            HSpacer {
            }
            Label {
                font.family: 'SF Compact Display'
                font.pixelSize: 14
                font.weight: 600
                text: qsTrId('Choose Asset')
            }
            HSpacer {
            }
            Item {
                Layout.minimumWidth: Math.max(left_item.implicitWidth, right_item.implicitWidth)
                id: right_item
            }
        }
    }
    contentItem: ColumnLayout {
        spacing: 5
        SearchField {
            Layout.fillWidth: true
            id: search_field
        }
        Item {
            Layout.minimumHeight: 25
        }
        Label {
            font.family: 'SF Compact Display'
            font.pixelSize: 14
            font.weight: 600
            opacity: 0.4
            text: search_field.text.trim().length > 0 ? 'Search result' : 'Other Assets'
        }
        GListView {
            id: list_view
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: -1
            clip: true
            model: AssetsModel {
//                    context: self.context
                filter: search_field.text.trim()
                minWeight: 1
            }
            spacing: 4
            delegate: ItemDelegate {
                required property Asset asset
                required property int index
                id: delegate
                width: ListView.view.contentWidth
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
                            AssetIcon {
                                asset: delegate.asset
                            }
                            Label {
                                Layout.fillWidth: true
                                font.family: 'SF Compact Display'
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
                                        font.family: 'SF Compact Display'
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
                                model: {
                                    const accounts = []
                                    for (let i = 0; i < self.context.accounts.length; i++) {
                                        const account = self.context.accounts[i]
                                        if (account.network.key === delegate.asset.network.key) {
                                            accounts.push(account)
                                        }
                                    }
                                    return accounts
                                }
                                delegate: SelectAccountButton {
                                    Layout.fillWidth: true
                                    id: button
                                    onClicked: self.selected(button.account, delegate.asset)
                                }
                            }
                            CreateAccountButton {
                                Layout.fillWidth: true
                                visible: self.showCreateAccount
                                onClicked: self.create(delegate.asset)
                            }
                        }
                    }
                }
            }
        }
    }

    component SelectAccountButton: AbstractButton {
        readonly property Account account: modelData
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
                    Layout.alignment: Qt.AlignCenter
                    font.family: 'SF Compact Display'
                    font.pixelSize: 14
                    font.weight: 500
                    text: button.account.name
                }
                Label {
                    font.family: 'SF Compact Display'
                    font.pixelSize: 11
                    font.weight: 400
                    opacity: 0.4
                    text: UtilJS.networkLabel(button.account.network) + ' / ' + UtilJS.accountLabel(button.account)
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
                font.family: 'SF Compact Display'
                font.pixelSize: 14
                font.weight: 500
                text: 'Create New Account'
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
