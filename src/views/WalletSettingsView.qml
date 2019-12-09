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
        background: Item {}
        id: tab_bar
        Layout.fillWidth: true
        TabButton {
            text: qsTr('id_general')
        }
        TabButton {
            text: qsTr('id_security')
        }
        TabButton {
            text: qsTr('id_advanced')
        }
    }

    StackLayout {
        id: stack_layout
        clip: true
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.topMargin: 10

        currentIndex: tab_bar.currentIndex

        ScrollView {
            WalletGeneralSettingsView {
                width: stack_layout.width - 20
            }
        }

        ScrollView {
            WalletSecuritySettingsView {
                width: stack_layout.width - 20
            }
        }

        ScrollView {
            WalletAdvancedSettingsView {
                width: stack_layout.width - 20
            }
        }
    }
}
