import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12
import ".."
import "../views"

Page {
    background: Item { }

    header: TabBar {
        id: tab_bar
        leftPadding: 8
        background: Item {}
        TabButton {
            text: qsTr('id_general')
            width: 160
        }
        TabButton {
            text: qsTr('id_security')
            width: 160
        }
        TabButton {
            text: qsTr('id_advanced')
            width: 160
        }
        TabButton {
            text: qsTr('id_recovery')
            width: 160
        }
    }

    StackLayout {
        anchors.fill: parent
        clip: true
        currentIndex: tab_bar.currentIndex

        ScrollView {
            contentWidth: width - 8 - 16
            WalletGeneralSettingsView {
                x: 8
                width: contentWidth
            }
        }

        ScrollView {
            contentWidth: width - 8 - 16
            WalletSecuritySettingsView {
                x: 8
                width: contentWidth
            }
        }

        ScrollView {
            contentWidth: width - 8 - 16
            WalletAdvancedSettingsView {
                x: 8
                width: contentWidth
            }
        }

        ScrollView {
            contentWidth: width - 8 - 16
            WalletRecoverySettingsView {
                x: 8
                width: contentWidth
            }
        }
    }
}
