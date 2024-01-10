import Blockstream.Green.Core
import Blockstream.Green
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import QtQml

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

MainPageHeader {
    signal assetsClicked()
    signal settingsClicked()
    signal archivedAccountsClicked()
    signal logoutClicked()

    required property Context context
    required property Wallet wallet
    required property Account currentAccount
    readonly property bool archived: self.currentAccount ? self.currentAccount.hidden : false
    required property real accountListWidth
    property Item toolbarItem: toolbar
    id: self

    readonly property bool busy: {
        if (self.context?.dispatcher.busy ?? false) return true
        const accounts = self.context?.dispatcher.busy ?? false
        for (let i = 0; i < accounts.length; i++) {
            if (!accounts[i].synced) return true
        }
        return false
    }

    topPadding: 0
    leftPadding: 0
    rightPadding: 0

    component HPane: GPane {
        padding: 4
        Layout.fillWidth: true
        leftPadding: 0
        rightPadding: 0
        background: null
    }

    component WalletMenu: GMenu {
        id: menu
        GMenu.Item {
            enabled: name_field_loader.active
            text: qsTrId('id_rename')
            icon.source: 'qrc:/svg/wallet-rename.svg'
            onClicked: {
                menu.close()
                name_field_loader.item.forceActiveFocus()
            }
        }
        GMenu.Separator {
        }
        GMenu.Item {
            text: qsTrId('id_settings')
            icon.source: 'qrc:/svg/wallet-settings.svg'
            onClicked: {
                menu.close()
                self.settingsClicked()
            }
        }
        GMenu.Separator {
        }
        GMenu.Item {
            text: qsTrId('id_add_new_account')
            icon.source: 'qrc:/svg/new.svg'
            enabled: !self.context.watchonly
            onClicked: {
                menu.close()
                openCreateAccountDrawer()
            }
        }
        GMenu.Item {
            text: qsTrId('id_refresh')
            icon.source: 'qrc:/svg2/refresh.svg'
            enabled: !(self.context?.dispatcher.busy ?? false)
            onClicked: {
                menu.close()
                self.context.refreshAccounts()
            }
        }
        GMenu.Separator {
        }
        GMenu.Item {
            text: qsTrId('id_view_archived_accounts_d').arg(archive_list_model.count)
            icon.source: 'qrc:/svg/archived.svg'
            enabled: archive_list_model.count > 0 && !(navigation.param.archive ?? false)
            onClicked: {
                menu.close()
                self.archivedAccountsClicked()
            }
        }
        GMenu.Separator {
        }
        GMenu.Item {
            text: qsTrId('id_logout')
            icon.source: 'qrc:/svg/logout.svg'
            enabled: !!self.context
            onClicked: {
                menu.close()
                self.logoutClicked()
            }
        }
    }

    contentItem: ColumnLayout {
        spacing: 0
        AlertView {
            id: alert_view
            alert: overview_alert
        }
        HPane {
            contentItem: RowLayout {
                spacing: 0
                Control {
                    Layout.maximumWidth: self.width / 3
                    padding: 2
                    leftPadding: 0
                    background: null
                    contentItem: RowLayout {
                        spacing: 0
                        Label {
                            verticalAlignment: Qt.AlignVCenter
                            text: qsTrId('id_overview')
                            font.pixelSize: 24
                            font.weight: 700
                        }
                        Label {
                            verticalAlignment: Qt.AlignVCenter
                            leftPadding: 8
                            color: '#FFF'
                            text: '/'
                            opacity: 0.2
                            font.pixelSize: 24
                            font.weight: 700
                        }
                        Loader {
                            id: name_field_loader
                            active: self.wallet.persisted
                            visible: active
                            Layout.fillWidth: true
                            sourceComponent: EditableLabel {
                                id: editable_label
                                leftPadding: 8
                                rightPadding: 8
                                font.pixelSize: 24
                                font.weight: 700
                                text: self.wallet.name
                                onAccepted: () => {
                                    if (self.wallet.rename(editable_label.text, false)) {
                                        Analytics.recordEvent('wallet_rename')
                                    }
                                    tool_button.forceActiveFocus()
                                }
                                onEdited: (text, activeFocus) => {
                                    if (self.wallet.rename(text, activeFocus)) {
                                        Analytics.recordEvent('wallet_rename')
                                    }
                                }
                            }
                        }
                        Loader {
                            Layout.minimumHeight: 42
                            active: !self.wallet.persisted
                            visible: active
                            sourceComponent: Label {
                                verticalAlignment: Qt.AlignVCenter
                                text: self.wallet.name
                                font.pixelSize: 24
                                font.weight: 700
                            }
                        }
                    }
                }
                CircleButton {
                    id: tool_button
                    icon.source: 'qrc:/svg/3-h-dots.svg'
                    onClicked: if (!wallet_menu.visible) wallet_menu.open()
                    WalletMenu {
                        id: wallet_menu
                        x: (tool_button.width - wallet_menu.width) / 2
                        y: tool_button.height + 8
                    }
                }
                HSpacer {
                }
                RowLayout {
                    Layout.fillWidth: false
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    spacing: constants.s1
                    visible: opacity > 0
                    opacity: self.context?.dispatcher.busy ?? false ? 0.8 : 0
                    Behavior on opacity {
                        SmoothedAnimation {
                            velocity: 2
                        }
                    }
                    Label {
                        text: {
                            let name = ''
                            const groups = self.context?.dispatcher?.groups ?? []
                            for (let i = 0; i < groups.length; i++) {
                                const group = groups[i]
                                if (group.status === TaskGroup.Active && group.name) {
                                    name = qsTrId(group.name)
                                }
                            }
                            return name
                        }
                    }
                    ProgressIndicator {
                        Layout.minimumHeight: 24
                        Layout.minimumWidth: 24
                        indeterminate: self.busy
                        current: 0
                        max: 1
                    }
                }
                ToolButton {
                    visible: (self.currentAccount?.session?.events?.twofactor_reset?.is_active ?? false) || !fiatRateAvailable
                    icon.source: 'qrc:/svg/notifications_2.svg'
                    icon.color: 'transparent'
                    icon.width: 16
                    icon.height: 16
                    onClicked: notifications_drawer.open()
                }
            }
        }
        HPane {
            Layout.bottomMargin: 20
            contentItem: CardBar {
                context: self.context
                onAssetsClicked: self.assetsClicked()
            }
        }
        HPane {
            contentItem: RowLayout {
                id: toolbar
                Layout.fillWidth: true
                Layout.fillHeight: false
                spacing: 24
                Label {
                    Layout.minimumWidth: self.accountListWidth
                    text: qsTrId('id_accounts')
                    font.pixelSize: 16
                    font.bold: true
                }
                RowLayout {
                    Layout.fillWidth: false
                    spacing: 24
                    TabButton2 {
                        view: 'transactions'
                    }
                    TabButton2 {
                        view: 'addresses'
                    }
                    TabButton2 {
                        view: 'coins'
                    }
                    TabButton2 {
                        view: 'assets'
                        enabled: self.currentAccount?.network.liquid ?? false
                    }
                }
                HSpacer {
                }
            }
        }
    }

    component TabButton2: Button {
        id: tab_button
        required property string view
        padding: 0
        verticalPadding: 0
        topPadding: 4
        bottomPadding: 4
        leftPadding: 0
        rightPadding: 0
        background: null
        checked: navigation.param.view === tab_button.view
        visible: enabled
        action: Action {
            text: qsTrId('id_' + tab_button.view)
            shortcut: {
                let j = -1
                for (let i = 0; i < parent.children.length; i++) {
                    const item = parent.children[i]
                    if (!item.visible) continue
                    j ++
                    if (item === tab_button) return 'Ctrl+' + (j + 1)
                }
                return null
            }
            onTriggered: navigation.set({ view: tab_button.view })
        }
        contentItem: Label {
            text: tab_button.text
            opacity: tab_button.checked ? 1 : tab_button.hovered ? 0.8 : 0.5
            font.pixelSize: 16
            font.bold: true
            horizontalAlignment: Label.AlignHCenter
        }
    }
}
