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
        padding: 20

        background: Item {}
        id: tab_bar
        TabButton {
            text: qsTr('id_general')
            width: 120
        }
        TabButton {
            text: qsTr('id_security')
            width: 120
        }
        TabButton {
            text: qsTr('id_advanced')
            width: 120
        }
        TabButton {
            text: qsTr('id_recovery')
            width: 120
        }
    }

    StackLayout {
        id: stack_layout
        clip: true
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20

        currentIndex: tab_bar.currentIndex

        ScrollView {
            contentWidth: width
            WalletGeneralSettingsView {
                width: stack_layout.width
            }
        }

        ScrollView {
            contentWidth: width
            WalletSecuritySettingsView {
                width: stack_layout.width
            }
        }

        ScrollView {
            contentWidth: width
            WalletAdvancedSettingsView {
                width: stack_layout.width
            }
        }

        ScrollView {
          contentWidth: width
            WalletRecoverySettingsView {
                width: stack_layout.width
            }
        }
    }
}
