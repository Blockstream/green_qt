import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Pane {
    enum View {
        Wallet,
        Wallets,
        Preferences
    }

    signal preferencesClicked
    signal walletsClicked
    signal crashClicked
    signal simulateNotificationClicked(string type)

    property WalletView currentWalletView
    property OverviewPage currentOverviewPage: currentWalletView?.overviewPage ?? null

    property int currentView: SideBar.Wallets
    property real maximumWidth: 250
    readonly property real position: (width - self.implicitWidth) / (self.maximumWidth - self.implicitWidth)
    property bool backupCompleted: true

    function updateBackupCompleted() {
        const context = self.currentOverviewPage?.context
        if (!context) {
            self.backupCompleted = true
            return
        }
        self.backupCompleted = !Settings.isEventRegistered({
            walletId: context.xpubHashId,
            status: 'pending',
            type: 'wallet_backup'
        })
    }
    Behavior on width {
        enabled: !drag_handler.active
        SmoothedAnimation {
            id: width_animation
            velocity: 500
        }
    }

    id: self
    focusPolicy: Qt.ClickFocus
    topPadding: 30
    bottomPadding: 30
    leftPadding: 0
    rightPadding: 0
    background: Rectangle {
        color: '#181818'
        Rectangle {
            width: 1
            anchors.right: parent.right
            height: parent.height
            color: '#262626'
        }
        HoverHandler {
            cursorShape: Qt.SizeHorCursor
        }
        DragHandler {
            property real startWidth
            id: drag_handler
            dragThreshold: 1
            target: null
            enabled: !width_animation.running
            margin: 0
            onActiveChanged: {
                if (drag_handler.active) {
                    drag_handler.startWidth = self.width
                    self.width = Qt.binding(() => Math.max(self.implicitWidth, Math.min(self.maximumWidth, drag_handler.startWidth + drag_handler.xAxis.activeValue)))
                } else {
                    if (self.width - 100 < self.implicitWidth) {
                        Qt.callLater(() => { self.width = Qt.binding(() => self.implicitWidth) })
                    } else if (self.width + 100 > self.maximumWidth) {
                        Qt.callLater(() => { self.width = self.maximumWidth })
                    } else {
                        Qt.callLater(() => { self.width = drag_handler.startWidth })
                    }
                }
            }
        }
    }

    Component.onCompleted: self.updateBackupCompleted()
    onCurrentOverviewPageChanged: self.updateBackupCompleted()

    Connections {
        target: Settings
        function onRegisteredEventsCountChanged() {
            self.updateBackupCompleted()
        }
    }

    Connections {
        target: self.currentOverviewPage
        function onContextChanged() {
            self.updateBackupCompleted()
        }
    }
    contentItem: ColumnLayout {
        spacing: 0
        Logo {
        }
        WalletSideButton {
            icon.source: 'qrc:/svg/menu-home.svg'
            shortcut: 'Ctrl+1'
            text: qsTrId('id_home')
            view: OverviewPage.Home
        }
        WalletSideButton {
            icon.source: 'qrc:/svg/menu-transactions.svg'
            shortcut: 'Ctrl+2'
            text: qsTrId('id_transactions')
            view: OverviewPage.Transactions
        }
        WalletSideButton {
            icon.source: 'qrc:/svg/menu-security.svg'
            shortcut: 'Ctrl+3'
            text: qsTrId('id_security')
            view: OverviewPage.Security
            warningDot: !self.backupCompleted
        }
        WalletSideButton {
            icon.source: 'qrc:/svg/menu-settings.svg'
            shortcut: 'Ctrl+4'
            text: qsTrId('id_settings')
            view: OverviewPage.Settings
        }
        VSpacer {
        }
        SideButton {
            visible: Qt.application.arguments.indexOf('--debug') > 0
            icon.source: 'qrc:/svg2/bug.svg'
            text: 'Test'
            onClicked: menu.open()
            Menu {
                id: menu
                y: parent.height
                x: self.width
                MenuItem {
                    text: 'Crash'
                    onTriggered: self.crashClicked()
                }
                MenuItem {
                    text: 'System notification'
                    onTriggered: self.simulateNotificationClicked('system')
                }
                MenuItem {
                    text: 'Outage notification'
                    onTriggered: self.simulateNotificationClicked('outage')
                }
                MenuItem {
                    text: '2FA reset notification'
                    onTriggered: self.simulateNotificationClicked('2fa_reset')
                }
                MenuItem {
                    text: '2FA expired notification'
                    onTriggered: self.simulateNotificationClicked('2fa_expired')
                }
                MenuItem {
                    text: 'Warning notification'
                    onTriggered: self.simulateNotificationClicked('warning')
                }
                MenuItem {
                    text: 'Update notification'
                    onTriggered: self.simulateNotificationClicked('update')
                }
            }
        }
        SideButton {
            action: Action {
                shortcut: 'Ctrl+0'
                onTriggered: self.walletsClicked()
            }
            icon.source: 'qrc:/svg/menu-wallet.svg'
            isCurrent: self.currentView === SideBar.View.Wallets
            text: qsTrId('id_wallets')
        }
        SideButton {
            action: Action {
                shortcut: 'Ctrl+,'
                onTriggered: self.preferencesClicked()
            }
            icon.source: 'qrc:/a0a0a0/24/faders-horizontal.svg'
            isCurrent: self.currentView === SideBar.View.Preferences
            text: qsTrId('id_app_settings')
        }
    }

    component Logo: Pane {
        Layout.bottomMargin: 40
        Layout.fillWidth: true
        background: null
        clip: true
        padding: 0
        contentItem: RowLayout {
            spacing: 0
            HSpacer {
                Layout.preferredWidth: 0
                Layout.maximumWidth: 36
            }
            Image {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                source: 'qrc:/svg/home.svg'
            }
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                opacity: self.position
                Image {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    source: 'qrc:/svg/blockstream.svg'
                }
            }
        }
    }

    component SideButton: AbstractButton {
        property bool isCurrent: false
        property bool warningDot: false
        Layout.bottomMargin: 10
        Layout.fillWidth: true
        id: button
        clip: true
        bottomPadding: 12
        leftPadding: 24
        rightPadding: 24
        topPadding: 12
        background: Item {
            Rectangle {
                radius: 8 * self.position
                color: 'white'
                opacity: button.enabled && button.hovered ? 0.1 : 0
                Behavior on opacity {
                    SmoothedAnimation {
                        velocity: 1
                    }
                }
                x: 24 * self.position
                width: parent.width
                height: parent.height
            }
            Rectangle {
                color: 'transparent'
                radius: 8 * self.position
                border.width: 2
                border.color: '#00BCFF'
                visible: button.visualFocus
                x: 24 * self.position
                width: parent.width
                height: parent.height
            }
            Rectangle {
                color: '#00BCFF'
                visible: button.visualFocus || button.isCurrent
                x: parent.width - 2
                width: 2
                height: parent.height
            }
        }
        contentItem: RowLayout {
            spacing: 0
            HSpacer {
                Layout.maximumWidth: 12
            }
            Image {
                source: button.icon.source
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                id: label
                color: '#A0A0A0'
                font.pixelSize: 16
                font.weight: 600
                leftPadding: 12
                opacity: self.position
                text: button.text
                wrapMode: Label.NoWrap
            }
            Item {
                Layout.alignment: Qt.AlignVCenter
                Rectangle {
                    visible: button.warningDot
                    anchors.centerIn: parent
                    width: 10
                    height: 10
                    radius: 5
                    color: '#FF0000'
                    opacity: self.position
                }
            }
        }
    }

    component WalletSideButton: SideButton {
        required property int view
        required property string shortcut
        id: button
        isCurrent: self.currentOverviewPage?.view === button.view
        visible: !!self.currentOverviewPage
        action: Action {
            id: action
            shortcut: button.shortcut
            onTriggered: self.currentView === SideBar.Wallet && self.currentOverviewPage.showView(button.view)
        }
    }
}
