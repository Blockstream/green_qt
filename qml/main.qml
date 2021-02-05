import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.13
import QtQuick.Window 2.12

ApplicationWindow {
    id: window

    readonly property Wallet currentWallet: stack_view.currentItem.wallet || null
    readonly property Account currentAccount: stack_view.currentItem.currentAccount || null

    DeviceDiscoveryAgent {
    }

    Connections {
        target: WalletManager
        function onWalletAdded(wallet) {
            if (wallet.device) {
                switchToWallet(wallet)
            }
        }
        function onAboutToRemove(wallet) {
            if (currentWallet === wallet) {
                stack_view.replace(stack_view.initialItem)
            }
            const view = wallet_views[wallet]
            delete wallet_views[wallet]
            view.destroy()
        }
    }

    Component {
        id: container_component
        WalletContainerView {
            onCanceled2: {
                switchToWallet(null)
            }
        }
    }

    property var wallet_views: ({})
    function switchToWallet(wallet) {
        if (wallet) {
            let container = wallet_views[wallet]
            if (!container) {
                container = container_component.createObject(null, { wallet })
                wallet_views[wallet] = container
            }
            stack_view.replace(container, StackView.Immediate)
            wallet_list_view.currentIndex = wallet_list_view.model.indexOf(wallet)
        } else {
            stack_view.replace(stack_view.initialItem, StackView.Immediate)
            wallet_list_view.currentIndex = -1
        }
    }

    property var icons: ({
        'liquid': 'qrc:/svg/liquid.svg',
        'mainnet': 'qrc:/svg/btc.svg',
        'testnet': 'qrc:/svg/btc_testnet.svg'
    })

    function formatDateTime(date_time) {
        return new Date(date_time).toLocaleString(locale.dateTimeFormat(Locale.LongFormat))
    }

    function accountName(account) {
        return account ? (account.name === '' ? qsTrId('id_main_account') : account.name) : ''
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

    Component.onCompleted: {
        // Auto select wallet if just one wallet
        if (WalletManager.wallets.length === 1) {
            switchToWallet(WalletManager.wallets[0]);
        }
    }

    width: 1024
    height: 600
    minimumWidth: 900
    minimumHeight: 540
    visible: true
    title: {
        const parts = []
        if (currentWallet) {
            if (currentWallet.device) {
                parts.push(currentWallet.device.name);
            } else {
                parts.push(currentWallet.name);
            }
            if (currentAccount) parts.push(accountName(currentAccount));
        }
        parts.push('Blockstream Green');
        return parts.join(' - ');
    }

    DeviceListModel {
        id: device_list_model
    }

    header: RowLayout {
        ToolButton {
            id: tool_button
            text: '\u2630'
            checkable: true
            checked: true
            Layout.leftMargin: 8
        }
        MenuBar {
            background: Item {}
            Menu {
                title: qsTrId('File')
                width: fitMenuWidth(this)
                Action {
                    text: qsTrId('id_create_new_wallet')
                    onTriggered: create_wallet_action.trigger()
                }
                Action {
                    text: qsTrId('id_restore_green_wallet')
                    onTriggered: restore_wallet_action.trigger()
                }
                Menu {
                    title: qsTrId('id_export_transactions_to_csv_file')
                    enabled: currentWallet && currentWallet.authentication === Wallet.Authenticated
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
            Menu {
                title: qsTrId('Wallet')
                width: fitMenuWidth(this)
                MenuItem {
                    text: qsTrId('id_settings')
                    enabled: currentWallet && currentWallet.authentication === Wallet.Authenticated
                    onClicked: stack_view.currentItem.wallet_view.toggleSettings()
                }
                MenuItem {
                    enabled: currentWallet && currentWallet.connection !== Wallet.Disconnected && !currentWallet.device
                    text: qsTrId('id_log_out')
                    onClicked: currentWallet.disconnect()
                }
                MenuSeparator { }
                MenuItem {
                    text: qsTrId('id_add_new_account')
                    onClicked: create_account_dialog.createObject(window).open()
                    enabled: currentWallet && currentWallet.authentication === Wallet.Authenticated
                }
                MenuItem {
                    text: qsTrId('id_rename_account')
                    enabled: currentWallet && currentWallet.authentication === Wallet.Authenticated && currentAccount && !currentAccount.mainAccount
                    onClicked: rename_account_dialog.createObject(window, { account: currentAccount }).open()
                }
            }
            Menu {
                title: qsTrId('id_help')
                width: fitMenuWidth(this)
                Action {
                    text: qsTrId('id_about')
                    onTriggered: about_dialog.open()
                }
                Action {
                    text: qsTrId('id_support')
                    onTriggered: {
                        Qt.openUrlExternally("https://docs.blockstream.com/green/support.html")
                    }
                }
            }
        }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
        RowLayout {
            children: stack_view.currentItem.toolbar || null
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.alignment: Qt.AlignBottom
        }
    }


    SplitView {
        anchors.fill: parent
        handle: Item {
            implicitWidth: 4
            implicitHeight: 4
        }

        Rectangle {
            id: wallets_sidebar_item
            clip: true
            color: Qt.rgba(1, 1, 1, 0.01)

            SplitView.minimumWidth: tool_button.checked ? 300 : 64
            SplitView.maximumWidth: SplitView.minimumWidth
            Behavior on SplitView.minimumWidth {
                SmoothedAnimation {
                    velocity: 1000
                }
            }
            ListView {
                id: wallet_list_view
                clip: true
                height: wallets_sidebar_item.height
                width: Math.max(300, parent.width)
                currentIndex: -1
                model: WalletListModel {}
                delegate: ItemDelegate {
                    id: delegate
                    text: wallet.device ? wallet.device.name : wallet.name
                    leftPadding: 16
                    icon.color: 'transparent'
                    icon.source: icons[wallet.network.id]
                    icon.width: 32
                    icon.height: 32
                    width: wallet_list_view.width
                    highlighted: ListView.isCurrentItem
                    opacity: highlighted || hovered || tool_button.checked ? 1 : 0.25
                    Behavior on opacity { OpacityAnimator {} }
                    property bool valid: wallet.loginAttemptsRemaining > 0
                    onPressed: if (valid) switchToWallet(wallet)
                    Row {
                        visible: !valid || parent.hovered
                        anchors.right: parent.right
                        Menu {
                            id: wallet_menu
                            MenuItem {
                                enabled: wallet.connection !== Wallet.Disconnected && !wallet.device
                                text: qsTrId('id_log_out')
                                onTriggered: wallet.disconnect()
                            }
                            MenuItem {
                                enabled: wallet.connection === Wallet.Disconnected
                                text: qsTrId('id_remove_wallet')
                                onClicked: remove_wallet_dialog.createObject(window, { wallet }).open()
                            }
                        }
                        Label {
                            visible: wallet.loginAttemptsRemaining === 0
                            anchors.verticalCenter: parent.verticalCenter
                            text: '\u26A0'
                            font.pixelSize: 18
                            ToolTip.text: qsTrId('id_no_attempts_remaining')
                            ToolTip.visible: !valid && delegate.hovered
                            ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                        }
                        ToolButton {
                            text: '\u22EF'
                            onClicked: wallet_menu.open()
                        }
                    }
                }
                ScrollIndicator.vertical: ScrollIndicator {}
            }

        }

        StackView {
            id: stack_view
            SplitView.fillWidth: true
            focus: true
            clip: true
            initialItem: Intro {}
        }
    }

    Action {
        id: create_wallet_action
        text: qsTrId('id_create_new_wallet')
        onTriggered: stack_view.push(signup_view)
    }

    Action {
        id: restore_wallet_action
        text: qsTrId('id_restore_green_wallet')
        onTriggered: {
            stack_view.push(restore_view)
            tool_button.checked = false
        }
    }

    AboutDialog {
        id: about_dialog
    }

    Component {
        id: signup_view
        SignupView {
            onClose: stack_view.pop()
        }
    }

    Component {
        id: restore_view
        RestoreWallet {
            onRestored: switchToWallet(wallet)
            onCanceled: stack_view.pop()
        }
    }

    Component {
        id: rename_account_dialog
        RenameAccountDialog {}
    }

    Component {
        id: create_account_dialog
        CreateAccountDialog {
            wallet: currentWallet
        }
    }

    Component {
        id: remove_wallet_dialog
        AbstractDialog {
            title: qsTrId('id_remove_wallet')
            property Wallet wallet
            anchors.centerIn: parent
            modal: true
            onAccepted: {
                WalletManager.removeWallet(wallet)
            }
            ColumnLayout {
                spacing: 8
                Label {
                    text: qsTrId('id_backup_your_mnemonic_before')
                }
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
            }
            footer: DialogButtonBox {
                    Button {
                    text: qsTrId('id_remove')
                    DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                    enabled: confirm_field.text === wallet.name
                }
            }
        }
    }

    Column {
        spacing: 16
        anchors.margins: 16
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        Repeater {
            model: device_list_model
            delegate: ledger_delegate
        }
    }

    Component {
        id: ledger_delegate
        Pane {
            id: delegate
            required property Device device
            anchors.right: parent.right
            visible: controller.progress < 1
            leftPadding: 16
            rightPadding: 16
            bottomPadding: 8
            topPadding: 8
            width: 360

            LedgerDeviceController {
                id: controller
                device: delegate.device
            }
            background: Rectangle {
                color: Qt.lighter('#141a21', delegate.hovered ? 2 : 1.5)
                border.width: 1
                border.color: Qt.lighter('#141a21', delegate.hovered ? 2.5 : 2)
                radius: height / 2
            }
            contentItem: RowLayout {
                DeviceImage {
                    device: delegate.device
                    height: 24
                    Layout.maximumHeight: 24
                }
                Label {
                    visible: !controller.network
                    opacity: 0.5
                    font.pixelSize: 11
                    text: qsTrId('id_select_an_app_on_s').arg(controller.device.name)
                    horizontalAlignment: Label.AlignHCenter
                    Layout.fillWidth: true
                }
                Image {
                    visible: controller.network && controller.status !== 'locked'
                    sourceSize.width: 24
                    sourceSize.height: 24
                    source: controller.network ? icons[controller.network.id] : ''
                }
                ProgressBar {
                    indeterminate: controller.indeterminate
                    value: controller.progress
                    visible: controller.status === 'login'
                    Layout.fillWidth: true
                    Behavior on value { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                }
                Label {
                    visible: controller.status === 'locked'
                    opacity: 0.5
                    font.pixelSize: 11
                    text: 'Unlock and select app'
                    horizontalAlignment: Label.AlignHCenter
                    Layout.fillWidth: true
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
}
