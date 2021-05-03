import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.13
import QtQuick.Window 2.12

ApplicationWindow {
    id: window

    readonly property WalletView currentWalletView: stack_layout.currentWalletView
    readonly property Wallet currentWallet: currentWalletView ? currentWalletView.wallet : null
    readonly property Account currentAccount: currentWalletView ? currentWalletView.currentAccount : null
    Navigation {
        id: navigation
        location: '/home'
    }
    function matchesLocation(l) {
        return navigation.location.startsWith(l)
    }
    function childIndexForLocation(stack_layout) {
       for (let i = 0; i < stack_layout.children.length; ++i) {
           const child = stack_layout.children[i]
           if (!(child instanceof Item)) continue
           const l = child.location
           if (l && child.enabled && navigation.location.startsWith(l)) return i
       }
       return 0
    }
    function link(url, text) {
        return `<style>a:link { color: "#00B45A"; text-decoration: none; }</style><a href="${url}">${text || url}</a>`
    }

    property var icons: ({
        'liquid': 'qrc:/svg/liquid.svg',
        'mainnet': 'qrc:/svg/btc.svg',
        'testnet': 'qrc:/svg/btc_testnet.svg'
    })

    property Constants constants: Constants {}

    function formatDateTime(date_time) {
        return new Date(date_time).toLocaleString(locale.dateTimeFormat(Locale.LongFormat))
    }

    function walletName(wallet) {
        if (!wallet) return ''
        if (wallet.watchOnly) return qsTrId('%1 watch-only wallet').arg(wallet.username)
        return wallet.name
    }

    function accountName(account) {
        if (!account) return ''
        if (account.mainAccount) return qsTrId('id_main_account')
        if (account.wallet.watchOnly) return qsTrId('Account %1').arg(account.pointer)
        return account.name
    }

    function fitMenuWidth(menu) {
        let result = 0;
        let padding = 0;
        for (let i = 0; i < menu.count; ++i) {
            const item = menu.itemAt(i);
            result = Math.max(item.contentItem.implicitWidth, result);
            padding = Math.max(item.padding, padding);
        }
        return result + padding * 2;
    }

    x: Settings.windowX
    y: Settings.windowY
    width: Settings.windowWidth
    height: Settings.windowHeight

    onXChanged: Settings.windowX = x
    onYChanged: Settings.windowY = y
    onWidthChanged: Settings.windowWidth = width
    onHeightChanged: Settings.windowHeight = height
    onCurrentWalletChanged: {
        if (currentWallet && !currentWallet.device && !currentWallet.watchOnly) {
            Settings.updateRecentWallet(currentWallet.id)
        }
    }

    minimumWidth: 900
    minimumHeight: main_layout.implicitHeight + header.implicitHeight
    visible: true
    color: constants.c900
    title: {
        const parts = Qt.application.arguments.indexOf('--debugnavigation') > 0 ? [navigation.location] : []
        if (currentWallet) {
            if (currentWallet.device) {
                parts.push(currentWallet.device.name);
            } else {
                parts.push(font_metrics.elidedText(walletName(currentWallet), Qt.ElideRight, window.width / 3));
            }
            if (currentAccount) parts.push(font_metrics.elidedText(accountName(currentAccount), Qt.ElideRight, window.width / 3));
        }
        parts.push('Blockstream Green');
        return parts.join(' - ');
    }
    FontMetrics {
        id: font_metrics
    }

    header: MenuBar {
        component GMenuBarItem: MenuBarItem {
            id: self
            leftPadding: 16
            rightPadding: 16
            background: Item {
                Rectangle {
                    anchors.fill: parent
                    visible: self.highlighted
                    color: constants.c400
                    anchors.margins: 4
                    radius: 8
                }
            }
        }
        component GMenu: Menu {
            id: self
            width: fitMenuWidth(this)
        }

        background: Rectangle {
            color: constants.c600
            Rectangle {
                width: parent.width
                anchors.bottom: parent.bottom
                height: 1
                color: 'black'
                opacity: 0.5
            }
        }
        GMenuBarItem {
            menu: GMenu {
                title: qsTrId('File')
                Action {
                    text: qsTrId('id_create_new_wallet')
                    onTriggered: navigation.go('/signup')
                }
                Action {
                    text: qsTrId('id_restore_green_wallet')
                    onTriggered: navigation.go('/restore')
                }
                Menu {
                    title: qsTrId('id_export_transactions_to_csv_file')
                    enabled: currentWallet && currentWallet.ready
                    Repeater {
                        model: currentWallet ? currentWallet.accounts : null
                        MenuItem {
                            text: accountName(modelData)
                            onTriggered: {
                                const popup = export_transactions_popup.createObject(window, { account: modelData })
                                popup.open()
                            }
                        }
                    }
                }
                Action {
                    text: qsTrId('&Exit')
                    onTriggered: window.close()
                }
            }
        }
        GMenuBarItem {
            menu: Menu {
                title: qsTrId('Wallet')
                width: fitMenuWidth(this)
                MenuItem {
                    text: qsTrId('id_settings')
                    action: currentWalletView ? currentWalletView.settingsAction : null
                    enabled: !!currentWalletView
                }
                MenuItem {
                    enabled: currentWallet && currentWallet.session && currentWallet.session && !currentWallet.device
                    text: qsTrId('id_log_out')
                    onClicked: currentWallet.disconnect()
                }
                MenuSeparator { }
                MenuItem {
                    text: qsTrId('id_add_new_account')
                    onClicked: create_account_dialog.createObject(window, { wallet: currentWallet}).open()
                    enabled: currentWallet && currentWallet.ready
                }
                MenuItem {
                    text: qsTrId('id_rename_account')
                    enabled: currentWallet && currentWallet.ready && !currentWallet.locked && currentAccount && !currentAccount.mainAccount
                    onClicked: rename_account_dialog.createObject(window, { account: currentAccount }).open()
                }
            }
        }
        GMenuBarItem {
            menu: Menu {
                title: qsTrId('id_help')
                width: fitMenuWidth(this)
                Action {
                    text: qsTrId('id_about')
                    onTriggered: navigation.go('/home')
                }
                Action {
                    text: qsTrId('id_support')
                    onTriggered: Qt.openUrlExternally(constants.supportUrl)
                }
            }
        }
    }

    component WalletButton: SideButton {
        id: self
        required property Wallet wallet
        location: `/${wallet.network.id}/${wallet.id}`
        text: wallet.device ? wallet.device.name : walletName(wallet)
        busy: wallet.activities.length > 0
        icon.width: 16
        icon.height: 16
        leftPadding: 32
        icon.source: icons[wallet.network.id]
        visible: !Settings.collapseSideBar
        DeviceImage {
            Layout.minimumWidth: paintedWidth
            sourceSize.height: 16
            parent: self.contentItem
            visible: wallet.device
            device: wallet.device
        }
    }
    component SideSeparator: Rectangle {
        implicitHeight: 1
        color: 'white'
        opacity: 0.05
        Layout.fillWidth: true
    }
    component SideLabel: SectionLabel {
        topPadding: 16
        leftPadding: 4
        bottomPadding: 4
        font.pixelSize: 10
        font.styleName: 'Medium'
    }

    RowLayout {
        id: main_layout
        anchors.fill: parent
        spacing: 0
        Page {
            id: side_bar
            focusPolicy: Qt.ClickFocus
            Layout.fillHeight: true
            topPadding: 8
            bottomPadding: 8
            leftPadding: 8
            rightPadding: 8
            background: Rectangle {
                color: constants.c700
                Rectangle {
                    height: parent.height
                    anchors.right: parent.right
                    width: 1
                    color: 'black'
                    opacity: 0.5
                }
            }

            contentItem: ColumnLayout {
                spacing: 8
                SideButton {
                    id: home_button
                    icon.source: 'qrc:/svg/home.svg'
                    location: '/home'
                    text: 'Home'
                }
                SideLabel {
                    text: 'Wallets'
                }
                Flickable {
                    id: flickable
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    flickableDirection: Flickable.VerticalFlick
                    contentHeight: foo.height
                    contentWidth: foo.width
                    implicitWidth: foo.implicitWidth
                    ScrollIndicator.vertical: ScrollIndicator { }
                    ColumnLayout {
                        id: foo
                        width: Math.max(implicitWidth, flickable.width)
                        spacing: 8
                        SideButton {
                            icon.source: icons.liquid
                            location: '/liquid'
                            text: 'Liquid'
                        }
                        Repeater {
                            id: liquid_repeater
                            model: WalletListModel {
                                justReady: true
                                network: 'liquid'
                            }
                            WalletButton {
                            }
                        }
                        SideButton {
                            icon.source: icons.mainnet
                            location: mainnet_view.location
                            text: 'Bitcoin'
                        }
                        Repeater {
                            id: mainnet_repeater
                            model: WalletListModel {
                                justReady: true
                                network: 'mainnet'
                            }
                            WalletButton {
                            }
                        }
                        SideButton {
                            visible: Settings.enableTestnet
                            icon.source: icons.testnet
                            location: '/testnet'
                            text: 'Testnet'
                        }
                        Repeater {
                            id: testnet_repeater
                            model: WalletListModel {
                                justReady: true
                                network: 'testnet'
                            }
                            WalletButton {
                                visible: !Settings.collapseSideBar && Settings.enableTestnet
                            }
                        }
                        SideLabel {
                            text: qsTrId('id_devices')
                        }
                        SideButton {
                            icon.source: 'qrc:/svg/blockstream-logo.svg'
                            location: jade_view.location
                            count: jade_view.count
                            text: 'Blockstream'
                        }
                        SideButton {
                            icon.source: 'qrc:/svg/ledger-logo.svg'
                            location: ledger_view.location
                            count: ledger_view.count
                            isCurrent: navigation.location.startsWith(location)
                            text: 'Ledger'
                        }
                    }
                }
                Item {
                    Layout.minimumHeight: 16
                }
                SideButton {
                    icon.source: 'qrc:/svg/appsettings.svg'
                    location: '/preferences'
                    text: 'App Settings'
                    icon.width: 24
                    icon.height: 24
                }
            }
        }

        StackLayout {
            id: stack_layout
            Layout.fillWidth: true
            Layout.fillHeight: true
            readonly property WalletView currentWalletView: currentIndex < 0 ? null : (stack_layout.children[currentIndex].currentWalletView || null)
            currentIndex: childIndexForLocation(stack_layout)
            HomeView {
                readonly property string location: '/home'
            }
            PreferencesView {
                id: settings_view
                readonly property string location: '/preferences'
            }
            JadeView {
                id: jade_view
                readonly property string location: '/jade'
            }
            LedgerView {
                id: ledger_view
                readonly property string location: '/ledger'
            }
            NetworkView {
                id: mainnet_view
                readonly property string location: '/mainnet'
                network: 'mainnet'
                title: qsTrId('id_bitcoin_wallets')
            }
            NetworkView {
                readonly property string location: '/liquid'
                network: 'liquid'
                title: qsTrId('id_liquid_wallets')
            }
            NetworkView {
                enabled: Settings.enableTestnet
                readonly property string location: '/testnet'
                network: 'testnet'
                title: qsTrId('id_testnet_wallets')
            }
        }
    }

    Route {
        id: signup_route
        location: navigation.location
        path: '/signup'
    }

    DialogLoader {
        active: signup_route.active
        dialog: SignupDialog {
            onRejected: navigation.go(signup_route.previous)
        }
    }

    Route {
        id: restore_route
        location: navigation.location
        path: '/restore'
    }

    DialogLoader {
        active: restore_route.active
        dialog: RestoreDialog {
            onRejected: navigation.go('/home')
        }
    }

    Route {
        readonly property Wallet wallet: {
            const [,, wallet_id] = navigation.path.split('/')
            const wallet = WalletManager.wallet(wallet_id)
            return wallet
        }
        id: login_route
        location: navigation.location
        path: wallet && !wallet.ready ? navigation.location : ''
    }

    DialogLoader {
        properties: ({ wallet: login_route.wallet })
        active: login_route.active
        dialog: LoginDialog {
            onRejected: navigation.go(login_route.previous)
        }
    }

    DebugActiveFocus {
    }

    Component {
        id: rename_account_dialog
        RenameAccountDialog {}
    }

    Component {
        id: create_account_dialog
        CreateAccountDialog {}
    }

    Component {
        id: remove_wallet_dialog
        AbstractDialog {
            title: qsTrId('id_remove_wallet')
            property Wallet wallet
            anchors.centerIn: parent
            modal: true
            onAccepted: WalletManager.removeWallet(wallet)
            contentItem: ColumnLayout {
                spacing: 16
                SectionLabel {
                    text: qsTrId('id_name')
                }
                Label {
                    text: wallet.name
                }
                SectionLabel {
                    text: qsTrId('id_network')
                }
                Row {
                    spacing: 8
                    Image {
                        sourceSize.width: 16
                        sourceSize.height: 16
                        source: icons[wallet.network.id]
                    }
                    Label {
                        text: wallet.network.name
                    }
                }
                SectionLabel {
                    text: qsTrId('id_confirm_action')
                }
                TextField {
                    Layout.minimumWidth: 300
                    id: confirm_field
                    placeholderText: qsTrId('id_confirm_by_typing_the_wallet')
                }
                Label {
                    text: qsTrId('id_backup_your_mnemonic_before')
                }
            }
            footer: Pane {
                rightPadding: 16
                bottomPadding: 8
                background: null
                contentItem: RowLayout {
                    HSpacer {
                    }
                    GButton {
                        enabled: confirm_field.text === wallet.name
                        destructive: true
                        large: true
                        text: qsTrId('id_remove')
                        onClicked: accept()
                    }
                }
            }
        }
    }

    Component {
        id: export_transactions_popup
        Popup {
            required property Account account
            id: dialog
            anchors.centerIn: Overlay.overlay
            closePolicy: Popup.NoAutoClose
            modal: true
            Overlay.modal: Rectangle {
                color: "#70000000"
            }
            onClosed: destroy()
            onOpened: controller.save()
            ExportTransactionsController {
                id: controller
                account: dialog.account
                onSaved: dialog.close()
            }
            BusyIndicator {}
        }

    }
    Component {
        id: session_tor_cirtcuit_view
        SessionTorCircuitToolButton {
        }
    }
    Component {
        id: session_connect_view
        SessionConnectToolButton {
        }
    }
}
