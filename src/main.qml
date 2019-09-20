import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.13
import QtQuick.Window 2.12

SplitView {
    id: split_view
    spacing: 0
    focus: true
    anchors.fill: parent

    handle: Rectangle {
        implicitWidth: 4
        color: Qt.rgba(0, 0, 0, 0.2)
    }

    Action {
        id: create_wallet_action
        onTriggered: stack_view.currentIndex = 1
    }

    Action {
        id: restore_wallet_action
        onTriggered: stack_view.push(restore_view)
    }

    MainMenuBar { }

    Sidebar {
        id: sidebar
        SplitView.minimumWidth: 200
        SplitView.maximumWidth: 400
        SplitView.fillHeight: true
    }

    StackLayout {
        id: stack_view
        clip: true
        focus: true

        SplitView.fillWidth: true
        SplitView.fillHeight: true
        SplitView.minimumWidth: implicitWidth

        Intro { }

        SignupView { }

        Repeater {
            model: WalletManager.wallets

            WalletFoo {
                property bool current: currentWallet === modelData

                onCurrentChanged: if (current) stack_view.currentIndex = index + 2
                wallet: modelData
            }
        }
    }

    Component {
        id: wallet_foo

        WalletFoo { }
    }

    Component {
        id: device_view_component

        DeviceView { }
    }
}
