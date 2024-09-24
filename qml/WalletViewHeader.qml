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
    signal statusClicked()
    signal notificationsClicked()
    signal logoutClicked()

    required property Context context
    required property Wallet wallet
    required property Account currentAccount
    readonly property bool archived: self.currentAccount ? self.currentAccount.hidden : false
    required property real accountListWidth
    property Item toolbarItem: toolbar
    property string view: 'transactions'
    id: self

    readonly property bool busy: {
        if (self.context?.dispatcher.busy ?? false) return true
        const accounts = self.context?.accounts ?? []
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
            enabled: self.currentAccount
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
        GMenu.Separator {
        }
        GMenu.Item {
            text: qsTrId('id_refresh')
            icon.source: 'qrc:/svg2/refresh.svg'
            enabled: self.currentAccount && !(self.context?.dispatcher.busy ?? false)
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
            enabled: archive_list_model.count > 0
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
                    Layout.maximumWidth: self.width / 2
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
                            Layout.leftMargin: 8
                            verticalAlignment: Qt.AlignVCenter
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
                            Layout.leftMargin: 8
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
                    Layout.leftMargin: 6
                    Layout.rightMargin: 6
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
                    visible: self.context?.dispatcher.busy ?? false
                    Label {
                        text: {
                            let name = ''
                            const groups = self.context?.dispatcher?.groups ?? []
                            for (let i = 0; i < groups.length; i++) {
                                const group = groups[i]
                                if (!group) continue
                                for (let j = 0; j < group.tasks.length; j++) {
                                    const task  = group.tasks[j]
                                    if (task.status === Task.Active) {
                                        return task.type
                                    }
                                }

                                // if (group.status === TaskGroup.Active && group.name) {
                                //     name = qsTrId(group.name)
                                // }
                            }
                            // return name
                            return ''
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
                CircleButton {
                    Layout.margins: 10
                    icon.source: 'qrc:/svg2/globe.svg'
                    onClicked: self.statusClicked()
                }
                NotificationsButton {
                    Layout.margins: 10
                }
            }
        }
        HPane {
            Layout.bottomMargin: 10
            leftPadding: 84
            rightPadding: 16
            padding: 16
            visible: self.context.bip39
            background: Rectangle {
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.04)
                color: '#161921'
                radius: 8
                Image {
                    anchors.left: parent.left
                    anchors.leftMargin: 36
                    anchors.verticalCenter: parent.verticalCenter
                    source: 'qrc:/svg2/passphrase.svg'
                }
            }
            contentItem: ColumnLayout {
                spacing: 10
                Label {
                    font.pixelSize: 14
                    font.weight: 600
                    text: qsTrId('id_password_protected')
                }
                Label {
                    text: qsTrId('id_this_wallet_is_based_on_your')
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
            visible: self.currentAccount
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
        checked: self.view === tab_button.view
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
            onTriggered: self.view = tab_button.view
        }
        contentItem: Label {
            text: tab_button.text
            opacity: tab_button.checked ? 1 : tab_button.hovered ? 0.8 : 0.5
            font.pixelSize: 16
            font.bold: true
            horizontalAlignment: Label.AlignHCenter
        }
    }

    component NotificationsButton: CircleButton {
        readonly property int count: self.context.notifications.length
        readonly property int unseen: {
            let count = 0
            const notifications = self.context.notifications
            for (let i = 0; i < notifications.length; i++) {
                if (!notifications[i].seen) count ++
            }
            return count
        }
        id: button
        icon.source: 'qrc:/svg2/bell.svg'
        onClicked: self.notificationsClicked()
        Label {
            id: unseen_label
            anchors.top: parent.top
            anchors.right: parent.right
            z: 1
            text: button.unseen
            visible: button.unseen > 0
            color: 'white'
            font.pixelSize: 10
            font.weight: 600
            padding: 0
            background: Item {
                Rectangle {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    color: 'red'
                    radius: 7
                }
            }
        }
    }
}
