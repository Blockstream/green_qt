import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12
import QtQuick.Window 2.12

SplitView {
    id: split_view

    Action {
        id: create_wallet_action
        onTriggered: stack_view.currentIndex = 1 //push(signup_view)
    }

    Action {
        id: restore_wallet_action
        onTriggered: stack_view.push(restore_view)
    }

    MainMenuBar {
    }

    spacing: 0
    anchors.fill: parent

    focus: true

    handle: Rectangle {
        implicitWidth: 4
        color: Qt.rgba(0, 0, 0, 0.2)
    }

    SideBar { // rename to Sidebar
        id: sidebar
        SplitView.minimumWidth: 200
        SplitView.maximumWidth: 400
        SplitView.fillHeight: true
    }

    StackLayout {
        id: stack_view

        clip: true
        focus: true

        //onCurrentItemChanged: currentItem.forceActiveFocus()

        //            initialItem: Intro {}

        Intro {}

        SignupView {

        }

        Repeater {
            model: WalletManager.wallets
            WalletFoo {
                id: foo
                property bool current: currentWallet === modelData
                onCurrentChanged: if (current) stack_view.currentIndex = index + 2
                wallet: modelData
            }
        }


//            RestoreWallet {
//                //onCanceled: stack_view.pop()
//            }

//            WalletFoo {
//                id: wallet_foo
//            }

//            DeviceView {
//            }

        SplitView.fillWidth: true
        SplitView.fillHeight: true
        SplitView.minimumWidth: implicitWidth
    }

    Component {
        id: wallet_foo
        WalletFoo {}
    }

    Component {
        id: device_view_component
        DeviceView {

        }
    }

    DebugActiveFocus {
        visible: false
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
    }

}

/*
    Component {
        id: signup_view
        SignupView {
            onCanceled: stack_view.pop()
        }
    }
    Component {
        id: restore_view
        RestoreWallet {
            //onCanceled: stack_view.pop()
        }
    }
*/
