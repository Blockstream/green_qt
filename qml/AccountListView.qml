import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

SwipeView {
    required property Wallet wallet
    property Account currentAccount: {
        const view = showArchived ? archive_list_view : account_list_view
        return view.currentItem ? view.currentItem.account : null
    }
    property bool showArchived: false

    function openCreateDialog() {
        const dialog = create_account_dialog.createObject(window, { wallet })
        dialog.accepted.connect(() => {
            // automatically select the last account since it is the newly created account
            // if account ordering is added then if should determine the correct index
            account_list_view.currentIndex = account_list_view.count - 1;
        })
        dialog.open()
    }

    Connections {
        target: archive_list_view
        function onCountChanged() {
            if (showArchived && archive_list_view.count === 0) showArchived = false
        }
    }

    Connections {
        target: Settings
        function onEnableExperimentalChanged() {
            if (showArchived && !Settings.enableExperimental) showArchived = false
        }
    }

    id: self
    interactive: false
    currentIndex: showArchived ? 1 : 0
    clip: true
    spacing: constants.p1

    Page {
        background: null
        header: GHeader {
            Label {
                Layout.alignment: Qt.AlignVCenter
                text: qsTrId('id_accounts')
                font.pixelSize: 20
                font.styleName: 'Bold'
                verticalAlignment: Label.AlignVCenter
            }
            HSpacer {
            }
            GButton {
                enabled: !wallet.watchOnly
                visible: !Settings.enableExperimental
                Layout.alignment: Qt.AlignVCenter
                text: '+'
                font.pixelSize: 14
                font.styleName: 'Medium'
                onClicked: openCreateDialog()
            }
            GButton {
                visible: Settings.enableExperimental
                Layout.alignment: Qt.AlignVCenter
                icon.source: 'qrc:/svg/kebab.svg'
                icon.height: 14
                icon.width: 14
                enabled: !menu.opened
                Menu {
                    id: menu
                    width: 300
                    MenuItem {
                        enabled: !wallet.watchOnly
                        text: qsTrId('id_add_new_account')
                        onTriggered: openCreateDialog()
                    }
                    MenuItem {
                        enabled: !showArchived && archive_list_view.count > 0
                        text: qsTrId('id_view_archived_accounts_d').arg(archive_list_view.count)
                        onTriggered: showArchived = !showArchived
                    }
                }
                onClicked: menu.popup()
            }
        }
        contentItem: GListView {
            id: account_list_view
            clip: true
            spacing: 0
            model: AccountListModel {
                wallet: self.wallet
                filter: '!hidden'
            }
            delegate: AccountDelegate {
            }
        }
    }

    Page {
        background: null
        header: RowLayout {
            spacing: constants.s2
            GToolButton {
                icon.source: 'qrc:/svg/arrow_left.svg'
                Layout.alignment: Qt.AlignVCenter
                onClicked: showArchived = false
            }
            Label {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                text: qsTrId('id_archived_accounts')
                font.pixelSize: 20
                font.styleName: 'Bold'
                verticalAlignment: Label.AlignVCenter
            }
        }
        contentItem: GListView {
            id: archive_list_view
            clip: true
            spacing: 0
            model: AccountListModel {
                wallet: self.wallet
                filter: 'hidden'
            }
            delegate: AccountDelegate {
            }
        }
    }

    component AccountDelegate: Button {
        property Account account: modelData

        id: delegate
        focusPolicy: Qt.ClickFocus
        onClicked: {
            delegate.ListView.view.currentIndex = index
        }
        Menu {
            id: account_delegate_menu
            MenuItem {
                text: qsTrId('id_rename')
                onTriggered: {
                    delegate.ListView.view.currentIndex = index
                    name_field.forceActiveFocus()
                }
            }
            MenuItem {
                text: qsTrId('id_unarchive')
                onTriggered: delegate.account.show()
                visible: delegate.account.hidden
                height: visible ? implicitHeight : 0
            }
            MenuItem {
                text: qsTrId('id_archive')
                enabled: account_list_view.count > 1
                onTriggered: delegate.account.hide()
                visible: !delegate.account.hidden
                height: visible ? implicitHeight : 0
            }
        }
        background: Rectangle {
            color: delegate.highlighted ? constants.c700 : delegate.hovered ? constants.c700 : constants.c800
            radius: 4
            border.width: 1
            border.color: delegate.highlighted ? constants.g500 : constants.c700
            TapHandler {
                enabled: Settings.enableExperimental && delegate.highlighted
                acceptedButtons: Qt.RightButton
                onTapped: account_delegate_menu.popup()
            }
        }
        highlighted: currentAccount === delegate.account
        leftPadding: constants.p2
        rightPadding: constants.p2
        topPadding: constants.p2
        bottomPadding: constants.p2
        hoverEnabled: true
        width: ListView.view.contentWidth
        contentItem: ColumnLayout {
            spacing: 8
            RowLayout {
                spacing: 0
                EditableLabel {
                    id: name_field
                    Layout.fillWidth: true
                    font.styleName: 'Medium'
                    font.pixelSize: 14
                    leftInset: -8
                    rightInset: -8
                    text: accountName(account)
                    enabled: !account.wallet.watchOnly && delegate.ListView.isCurrentItem && !delegate.account.wallet.locked
                    onEdited: {
                        if (enabled) {
                            renameAccount(account, text, activeFocus)
                        }
                    }
                }
                Item {
                    implicitWidth: constants.s1
                }
                AccountTypeBadge {
                    account: delegate.account
                }
                Item {
                    visible: Settings.enableExperimental
                    implicitWidth: delegate.hovered || account_delegate_menu.opened ? constants.s1 + tool_button.width : 0
                    Behavior on implicitWidth {
                        SmoothedAnimation {}
                    }
                    implicitHeight: tool_button.height
                    clip: true
                    GToolButton {
                        id: tool_button
                        x: constants.s1
                        icon.source: 'qrc:/svg/kebab.svg'
                        onClicked: account_delegate_menu.popup()
                    }
                }
            }
            RowLayout {
                spacing: 2
                Repeater {
                    model: {
                        const assets = []
                        let without_icon = false
                        for (let i = 0; i < account.balances.length; i++) {
                            const { amount, asset }= account.balances[i]
                            if (amount === 0) continue;
                            if (asset.icon || !without_icon) assets.push(asset)
                            without_icon = !asset.icon
                        }
                        return assets
                    }
                    AssetIcon {
                        asset: modelData
                        size: 16
                    }
                }
                HSpacer {
                }
            }
            RowLayout {
                HSpacer {
                }
                CopyableLabel {
                    text: formatAmount(account.balance)
                    font.pixelSize: 14
                    font.styleName: 'Regular'
                }
                Label {
                    text: '≈'
                    font.pixelSize: 14
                    font.styleName: 'Regular'
                }
                CopyableLabel {
                    text: formatFiat(account.balance)
                    font.pixelSize: 14
                    font.styleName: 'Regular'
                }
            }
        }
    }
}
