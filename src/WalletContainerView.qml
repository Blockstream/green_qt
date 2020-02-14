import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

Page {
    property Wallet wallet

    background: Item {}

    header: Item {
        id: header_item
        height: column.implicitHeight
        ColumnLayout {
            id: column
            width: parent.width
            anchors.bottom: parent.bottom

            Image {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 128
                source: icons[wallet.network.id]
            }
            Label {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 32
                text: wallet.name
                font.pixelSize: 32
            }
        }
    }

    StackView {
        id: stack_view
        anchors.fill: parent
    }

    states: [
        State {
            when: wallet.connection === Wallet.Disconnected
            name: 'DISCONNECTED'
        },
        State {
            when: wallet.connection === Wallet.Connecting
            name: 'CONNECTING'
        },
        State {
            when: wallet.connection === Wallet.Connected && wallet.authentication === Wallet.Unauthenticated
            name: 'LOGIN'
        },
        State {
            when: wallet.connection === Wallet.Connected && wallet.authentication === Wallet.Authenticating
            name: 'LOGING'
        },
        State {
            when: wallet.connection === Wallet.Connected && wallet.authentication === Wallet.Authenticated
            name: 'LOGGED'
            PropertyChanges {
                target: header_item
                height: 0
            }
        }
    ]

    transitions: [
        Transition {
            to: 'DISCONNECTED'
            StackViewPushAction {
                stackView: stack_view
                Item { ConnectView { anchors.horizontalCenter: parent.horizontalCenter } }
            }
        },
        Transition {
            to: "CONNECTING"
            StackViewPushAction {
                stackView: stack_view
                Item { ConnectingView { anchors.horizontalCenter: parent.horizontalCenter } }
            }
        },
        Transition {
            to: 'LOGIN'
            StackViewPushAction {
                stackView: stack_view
                Item { LoginView { anchors.horizontalCenter: parent.horizontalCenter } }
            }
        },
        Transition {
            to: 'LOGING'
            StackViewPushAction {
                stackView: stack_view
                Item { ConnectingView { anchors.horizontalCenter: parent.horizontalCenter } }
            }
        },
        Transition {
            to: 'LOGGED'
            SequentialAnimation {
                StackViewPushAction {
                    stackView: stack_view
                    WalletView { }
                }
            }
        }
    ]
}
