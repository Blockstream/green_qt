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
        leftPadding: 16
        background: Item {}
        Repeater {
            model: stack_layout.children

            TabButton {
                text: modelData.title
                width: 160
            }
        }
    }

    StackLayout {
        id: stack_layout
        anchors.fill: parent
        clip: true
        currentIndex: tab_bar.currentIndex

        Repeater {
            property list<Component> views: [
                Component { WalletGeneralSettingsView {} },
                Component { WalletSecuritySettingsView {} },
                Component { WalletAdvancedSettingsView {} },
                Component { WalletRecoverySettingsView {} }
            ]
            model: views

            ScrollView {
                property string title: loader.item.title
                contentWidth: width - 32
                Loader {
                    id: loader
                    x: 16
                    width: contentWidth
                    sourceComponent: modelData
                }
            }
        }
    }
}
