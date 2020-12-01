import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

Page {
    id: view
    property Wallet wallet
    background: Item { }

    header: TabBar {
        id: tab_bar
        leftPadding: 16
        background: Item {}
        TabButton {
            text: general_settings_view.title
            width: 160
        }
        TabButton {
            text: security_settings_view.title
            width: 160
        }
        TabButton {
            text: recovery_settings_view.title
            width: 160
        }
    }

    StackLayout {
        id: stack_layout
        anchors.fill: parent
        clip: true
        currentIndex: tab_bar.currentIndex

        ScrollView {
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            contentWidth: availableWidth
            WalletGeneralSettingsView {
                id: general_settings_view
                wallet: view.wallet
                x: 16
                width: stack_layout.width - 32
            }
        }
        ScrollView {
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            contentWidth: availableWidth
            WalletSecuritySettingsView {
                id: security_settings_view
                wallet: view.wallet
                x: 16
                width: stack_layout.width - 32
            }
        }
        ScrollView {
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            contentWidth: availableWidth
            WalletRecoverySettingsView {
                id: recovery_settings_view
                wallet: view.wallet
                x: 16
                width: stack_layout.width - 32
            }
        }
    }
}
