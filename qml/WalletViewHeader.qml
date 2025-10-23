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
    signal settingsClicked()
    signal archivedAccountsClicked()
    signal statusClicked()
    signal notificationsClicked()
    signal logoutClicked()
    signal promoClicked(Promo promo)
    signal reportBugClicked()
    signal jadeDetailsClicked()

    required property Context context
    required property Wallet wallet
    required property int view
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
    bottomPadding: 16

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
            text: 'Get Support'
            icon.source: 'qrc:/svg2/headset.svg'
            onClicked: {
                menu.close()
                self.reportBugClicked()
            }
        }
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
        GMenu.Separator {
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
                            font.pixelSize: 24
                            font.weight: 700
                            text: {
                                if (self.view === OverviewPage.Home) return qsTrId('id_overview')
                                if (self.view === OverviewPage.Transactions) return qsTrId('id_transactions')
                                if (self.view === OverviewPage.Security) return qsTrId('id_security')
                                if (self.view === OverviewPage.Settings) return qsTrId('id_settings')
                            }
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
                    property real _opacity: -1
                    Layout.fillWidth: false
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    id: task_info_layout
                    spacing: constants.s1
                    opacity: Math.max(0, task_info_layout._opacity)
                    Behavior on _opacity {
                        SmoothedAnimation {
                            velocity: 3
                        }
                    }
                    Label {
                        property string task: {
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
                            }
                            return ''
                        }
                        id: task_label
                        onTaskChanged: {
                            if (task_label.task.length > 0) {
                                task_label.text = task_label.task
                                task_info_layout._opacity = 1
                            } else {
                                task_info_layout._opacity = -1
                            }
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
            contentItem: CardBar {
                context: self.context
                onJadeDetailsClicked: self.jadeDetailsClicked()
                onPromoClicked: (promo) => self.promoClicked(promo)
            }
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
