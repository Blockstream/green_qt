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
    property bool anyLiquid: false
    property bool anyAMP: false
    id: self
    title: qsTrId('Choose Asset')
    contentItem: ColumnLayout {
        spacing: 5
        SearchField {
            Layout.fillWidth: true
            id: search_field
            visible: false
        }
        FieldTitle {
            Layout.topMargin: 25
            text: {
                if (search_field.text.trim().length === 0) return 'Other Assets'
                if (list_view.count === 0) return 'No search results'
                return 'Search results'
            }
            visible: false
        }
        TListView {
            id: list_view
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: -1
            model: AssetsModel {
                filter: search_field.text.trim()
                deployment: self.context.deployment
                minWeight: 1
            }
            spacing: 4
            footer: ColumnLayout {
                width: list_view.width
                spacing: 0
                SelectorDelegate {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    amp: false
                    index: -1
                    icon.source: 'qrc:/svg2/liquid_icon.svg'
                    text: 'Receive any Liquid Asset'
                    highlighted: self.anyLiquid
                    onClicked: {
                        self.anyLiquid = !self.anyLiquid
                        self.anyAMP = false
                        list_view.currentIndex = -1
                    }
                }
                SelectorDelegate {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    amp: true
                    index: -1
                    icon.source: 'qrc:/svg2/amp_icon.svg'
                    text: 'Receive any AMP Asset'
                    highlighted: self.anyAMP
                    onClicked: {
                        self.anyLiquid = false
                        self.anyAMP = !self.anyAMP
                        list_view.currentIndex = -1
                    }
                }
            }
            delegate: SelectorDelegate {
                id: delegate
                width: ListView.view.width
                onClicked: {
                    self.anyLiquid = false
                    self.anyAMP = false
                    list_view.currentIndex = delegate.ListView.isCurrentItem ? -1 : delegate.index
                }
            }
        }
    }

    component SelectorDelegate: ItemDelegate {
        required property int index
        required property Asset asset
        property bool amp: delegate.asset.amp
        id: delegate
        icon.source: UtilJS.iconFor(delegate.asset)
        text: delegate.asset.name || delegate.asset.id
        padding: 0
        topPadding: 0
        bottomPadding: 0
        topInset: 0
        bottomInset: 0
        highlighted: delegate.ListView.isCurrentItem
        background: Rectangle {
            radius: 4
            color: '#2F2F35'
            border.width: delegate.highlighted ? 2 : 0
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
                        source: delegate.icon.source
                    }
                    Label {
                        Layout.fillWidth: true
                        font.pixelSize: 14
                        font.weight: 500
                        text: delegate.text
                        elide: Label.ElideMiddle
                    }
                }
                onClicked: delegate.clicked()
            }
            Collapsible {
                Layout.fillWidth: true
                collapsed: !delegate.highlighted
                contentWidth: width
                contentHeight: collapsible_layout.height
                ColumnLayout {
                    id: collapsible_layout
                    width: parent.width
                    spacing: 0
                    Pane {
                        Layout.fillWidth: true
                        padding: 10
                        visible: delegate.amp
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
                                text: {
                                    if (delegate.asset) {
                                        return `${delegate.asset.name} is an AMP asset. You need an AMP account in order to receive it.`
                                    } else {
                                        return 'You need an AMP account in order to receive AMP assets.'
                                    }
                                }
                                wrapMode: Label.WordWrap
                            }
                        }
                    }
                    Rectangle {
                        width: parent.width
                        height: 2
                        color: delegate.highlighted ? '#00B45A' : 'transparent'
                    }
                    Repeater {
                        id: accounts_repeater
                        model: {
                            const accounts = []
                            for (let i = 0; i < self.context.accounts.length; i++) {
                                const account = self.context.accounts[i]
                                if (account.hidden) continue
                                if (delegate.asset) {
                                    if (delegate.asset.networkKey === account.network.key) {
                                        if (!account.network.electrum || account.json.bip44_discovered || account.name.length > 0) {
                                            accounts.push(account)
                                        }
                                    }
                                } else if (self.anyLiquid) {
                                    if (account.network.liquid) {
                                        accounts.push(account)
                                    }
                                } else if (self.anyAMP) {
                                    if (account.type === '2of2_no_recovery') {
                                        accounts.push(account)
                                    }
                                }
                            }
                            return accounts
                        }
                        delegate: SelectAccountButton {
                            required property var modelData
                            Layout.fillWidth: true
                            id: button
                            asset: delegate.asset
                            account: button.modelData
                            onSelected: (account, asset) => self.selected(button.account, button.asset)
                        }
                    }
                    CreateAccountButton {
                        Layout.fillWidth: true
                        onClicked: {
                            self.StackView.view.push(create_account_page, {
                                asset: delegate.asset,
                                anyLiquid: self.anyLiquid,
                                anyAMP: self.anyAMP,
                            })
                        }
                    }
                }
            }
        }
    }

    component OptionButton: AbstractButton {
        Layout.fillWidth: true
        id: button
        leftPadding: 20
        rightPadding: 20
        topPadding: 10
        bottomPadding: 10
        background: Rectangle {
            color: Qt.lighter('#222226', button.hovered ? 1.2 : 1)
            radius: 5
            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                border.width: 2
                border.color: '#00B45A'
                color: 'transparent'
                radius: 9
                visible: {
                    if (button.activeFocus) {
                        switch (button.focusReason) {
                        case Qt.TabFocusReason:
                        case Qt.BacktabFocusReason:
                        case Qt.ShortcutFocusReason:
                            return true
                        }
                    }
                    return false
                }
                z: -1
            }
        }
        contentItem: RowLayout {
            spacing: 10
            Image {
                property real size: 32
                source: button.icon.source
                Layout.preferredHeight: size
                Layout.preferredWidth: size
                height: size
                width: size
                fillMode: Image.PreserveAspectFit
                mipmap: true
            }
            Label {
                Layout.fillWidth: true
                font.pixelSize: 14
                font.weight: 500
                text: button.text
                wrapMode: Label.WrapAtWordBoundaryOrAnywhere
            }
        }
    }

    component SelectAccountButton: AbstractButton {
        signal selected(Account account, Asset asset)
        required property Account account
        required property Asset asset
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
