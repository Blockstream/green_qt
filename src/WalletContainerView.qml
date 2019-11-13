import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

Page {
    property Wallet wallet

    StackView {
        id: stack_view
        anchors.fill: parent
    }

    states: [
        State {
            when: wallet.status === Wallet.Disconnected
            name: 'DISCONNECTED'
        },
        State {
            when: wallet.status === Wallet.Connecting
            name: 'CONNECTING'
        },
        State {
            when: wallet.status === Wallet.Connected
            name: 'LOGIN'
        },
        State {
            when: wallet.status === Wallet.Authenticating
            name: 'LOGING'
        },
        State {
            when: wallet.status === Wallet.Authenticated
            name: 'LOGGED'
        }
    ]

    transitions: [
        Transition {
            to: 'DISCONNECTED'
            StackViewPushAction {
                stackView: stack_view
                Item { ConnectView { anchors.centerIn: parent } }
            }
        },
        Transition {
            to: "CONNECTING"
            StackViewPushAction {
                stackView: stack_view
                Item { ConnectingView { anchors.centerIn: parent } }
            }
        },
        Transition {
            to: 'LOGIN'
            StackViewPushAction {
                stackView: stack_view
                Item { LoginView { anchors.centerIn: parent } }
            }
        },
        Transition {
            to: 'LOGING'
            StackViewPushAction {
                stackView: stack_view
                Item { ConnectingView { anchors.centerIn: parent } }
            }
        },
        Transition {
            to: 'LOGGED'
            StackViewPushAction {
                stackView: stack_view
                WalletView { }
            }
        }
    ]
}
