import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    signal selected(account: Account, asset: Asset)
    signal lightningSelected()
    required property Context context
    property bool anyLiquid: false
    property bool anyAMP: false
    property bool anyAMPLegacy: false
    readonly property bool supportsLiquid: self.context.sessions.some(session => session.network.liquid)
    readonly property bool hasAmp0Account: UtilJS.accounts(self.context).some(account => account.amp0)
    readonly property bool hasAmp2Account: UtilJS.accounts(self.context).some(account => account.amp2)
    readonly property var ampReceiveOptions: {
        const result = []
        if (self.context.mainnet) {
            // Only AMP0 for mainnet (displayed as AMP)
            if (self.hasAmp0Account) result.push({ legacy: false, text: 'Any AMP Asset' })
            return result
        }

        // Show AMP2 on testnet if user has AMP2 account (displayed as AMP)
        if (self.hasAmp2Account) result.push({ legacy: false, text: 'Any AMP Asset' })
        
        // Show AMP0 on testnet if user has AMP0 account (displayed as AMP Legacy)
        if (self.hasAmp0Account) result.push({ legacy: true, text: 'Any AMP Legacy Asset' })
        return result
    }
    function accountMatchesAmpSelection(account) {
        if (!account) return false
        if (self.anyAMP) return self.context.mainnet ? account.amp0 : account.amp2
        if (self.anyAMPLegacy) return !self.context.mainnet && account.amp0
        return false
    }
    id: self
    title: qsTrId('id_select_account__asset')
    footer: null
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    contentItem: ColumnLayout {
        spacing: 5
        SearchField {
            Layout.fillWidth: true
            id: search_field
        }
        TListView {
            id: list_view
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: -1
            model: AssetsModel {
                filter: search_field.text.trim()
                context: self.context
                minWeight: search_field.text.trim().length > 0 ? 0 : 1
                showAmp: self.hasAmp0Account
                showLightning: true
            }
            spacing: 5
            footer: ColumnLayout {
                width: list_view.width
                spacing: 0
                SelectorDelegate {
                    Layout.fillWidth: true
                    Layout.topMargin: 5
                    amp: false
                    asset: null
                    enabled: self.supportsLiquid
                    index: -1
                    icon.source: 'qrc:/svg2/liquid_icon.svg'
                    text: 'Any Liquid Asset'
                    highlighted: self.anyLiquid
                    onClicked: {
                        self.anyLiquid = !self.anyLiquid
                        self.anyAMP = false
                        self.anyAMPLegacy = false
                        list_view.currentIndex = -1
                    }
                }
                Repeater {
                    model: self.ampReceiveOptions
                    delegate: SelectorDelegate {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.topMargin: 5
                        amp: true
                        asset: null
                        enabled: self.supportsLiquid
                        index: -1
                        icon.source: 'qrc:/svg2/amp_icon.svg'
                        text: modelData.text
                        highlighted: modelData.legacy ? self.anyAMPLegacy : self.anyAMP
                        onClicked: {
                            const checked = modelData.legacy ? self.anyAMPLegacy : self.anyAMP
                            self.anyLiquid = false
                            self.anyAMP = modelData.legacy ? false : !checked
                            self.anyAMPLegacy = modelData.legacy ? !checked : false
                            list_view.currentIndex = -1
                        }
                    }
                }
            }
            delegate: SelectorDelegate {
                id: delegate
                width: ListView.view.width
                onClicked: {
                    if (delegate.asset?.lightning) {
                        self.lightningSelected()
                        return
                    }
                    self.anyLiquid = false
                    self.anyAMP = false
                    self.anyAMPLegacy = false
                    list_view.currentIndex = delegate.ListView.isCurrentItem ? -1 : delegate.index
                }
            }
        }
    }

    component SelectorDelegate: ItemDelegate {
        required property int index
        required property Asset asset
        property bool amp: delegate.asset?.amp ?? false
        id: delegate
        icon.source: delegate.asset ? UtilJS.assetIcon(delegate.asset) : ''
        text: delegate.asset?.name || delegate.asset?.id || ''
        padding: 0
        topPadding: 0
        bottomPadding: 0
        topInset: 0
        bottomInset: 0
        highlighted: delegate.ListView.isCurrentItem
        background: Rectangle {
            radius: 4
            color: Qt.lighter('#181818', !delegate.highlighted && delegate.enabled && delegate.hovered ? 1.2 : 1)
            border.width: delegate.highlighted ? 2 : 1
            border.color: delegate.highlighted ? '#00BCFF' : '#262626'
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
                        property real size: 32
                        source: delegate.icon.source
                        Layout.preferredHeight: size
                        Layout.preferredWidth: size
                        height: size
                        width: size
                        fillMode: Image.PreserveAspectFit
                        mipmap: true
                        opacity: delegate.enabled ? 1 : 0.6
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
                    Rectangle {
                        width: parent.width
                        height: 2
                        color: delegate.highlighted ? '#00BCFF' : 'transparent'
                    }
                    Repeater {
                        id: accounts_repeater
                        model: {
                            const accounts = []
                            for (const account of UtilJS.accounts(self.context)) {
                                if (delegate.asset) {
                                    if (delegate.asset.networkKey !== account.network.key) continue
                                    if (delegate.asset.amp && !(account.amp0 || account.amp2)) continue
                                    accounts.push(account)
                                } else if (self.anyLiquid) {
                                    if (account.network.liquid) {
                                        accounts.push(account)
                                    }
                                } else if (self.anyAMP || self.anyAMPLegacy) {
                                    if (self.accountMatchesAmpSelection(account)) {
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
                        visible: !self.context.watchonly && !self.anyAMP && !self.anyAMPLegacy
                        onClicked: {
                            self.pushPage(create_account_page, {
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
            color: Qt.lighter('#262626', button.hovered ? 1.2 : 1)
            radius: 5
            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                border.width: 2
                border.color: '#00BCFF'
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
                    font.capitalization: Font.AllUppercase
                    font.pixelSize: 11
                    font.weight: 400
                    opacity: 0.4
                    text: UtilJS.accountDescription(button.account)
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
            onCloseClicked: self.closeClicked()
            onCreated: (account) => self.selected(account, page.asset)
        }
    }
}
