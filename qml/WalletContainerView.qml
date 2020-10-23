import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

StackView {
    id: stack_view

    required property Wallet wallet

    Connections {
        target: wallet
        function onLoginAttemptsRemainingChanged(loginAttemptsRemaining) {
            if (loginAttemptsRemaining === 0) {
                switchToWallet(null)
            }
        }
    }

    signal canceled2()

    initialItem: login_view

    property Item toolbar: currentItem.toolbar || null
    property Item login_view: Page {
        property Item toolbar: RowLayout {
            Label {
                visible: wallet.authentication === Wallet.Authenticating || wallet.connection === Wallet.Connecting
                opacity: wallet.events.tor !== undefined && wallet.events.tor.progress > 0 && wallet.events.tor.progress < 100 ? 0.5 : 0
                text: wallet.events.tor ? wallet.events.tor.summary : ''
                Behavior on opacity { OpacityAnimator {} }
            }
            ProgressBar {
                property var tor: wallet.events.tor
                Layout.maximumWidth: 64
                opacity: wallet.authentication === Wallet.Authenticating || wallet.connection === Wallet.Connecting ? 0.5 : 0
                from: 0
                indeterminate: !(tor && tor.progress >= 0 && tor.progress < 100)
                to: 100
                value: wallet.events.tor ? wallet.events.tor.progress : 0
                Behavior on opacity { OpacityAnimator {} }
                Behavior on value { SmoothedAnimation {} }
            }
            ToolButton {
                onClicked: settings_drawer.open()
                icon.source: 'qrc:/svg/settings.svg'
            }
            ToolButton {
                icon.source: 'qrc:/svg/cancel.svg'
                icon.width: 16
                icon.height: 16
                onClicked: {
                    canceled2()
                }
            }
        }

        background: Item {}

        header: Item {
            height: 64

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                spacing: 16
                Image {
                    anchors.verticalCenter: parent.verticalCenter
                    source: icons[wallet.network.id]
                }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: wallet.name
                    font.pixelSize: 32
                }
            }
        }

        Drawer {
            id: settings_drawer
            interactive: position > 0
            edge: Qt.RightEdge
            height: parent.height
            width: 300

            Overlay.modal: Rectangle {
                color: "#70000000"
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                Label {
                    text: 'Connection Settings'
                    font.pixelSize: 18
                    Layout.margins: 16
                }

                CheckBox {
                    id: proxy_checkbox
                    text: qsTrId('id_connect_through_a_proxy')
                    checked: wallet.proxy.length > 0
                }
                TextField {
                    id: proxy_field
                    Layout.leftMargin: 32
                    Layout.fillWidth: true
                    enabled: proxy_checkbox.checked
                    placeholderText: 'host:address'
                    text: wallet.proxy
                }
                CheckBox {
                    id: tor_checkbox
                    text: qsTrId('id_connect_with_tor')
                    checked: wallet.useTor
                }
                Item {
                   Layout.fillWidth: true
                   Layout.fillHeight: true
                }
            }
        }

        Collapsible {
            anchors.centerIn: parent
            collapsed: wallet.authenticated
            enabled: wallet.loginAttemptsRemaining > 0 && wallet.authentication === Wallet.Unauthenticated

            LoginView {
                onLogin: {
                    const proxy = proxy_checkbox.checked ? proxy_field.text : '';
                    const use_tor = tor_checkbox.checked;
                    wallet.connect(proxy, use_tor);
                    wallet.loginWithPin(pin);
                }
            }
        }
    }

    property Item wallet_view: WalletView {
        wallet: stack_view.wallet
    }

    Connections {
        target: wallet
        function onAuthenticationChanged(authentication) {
            if (wallet.authentication === Wallet.Authenticated) {
                stack_view.push(wallet_view);
            } else if (stack_view.depth > 1) {
                stack_view.pop();
            }
        }
    }

    Component.onCompleted: {
        if (wallet.authentication === Wallet.Authenticated) {
            stack_view.push(wallet_view);
        }
    }
}
