import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

StackView {
    id: stack_view

    property Wallet wallet

    signal canceled2()

    initialItem: login_view

    property Component toolbar: currentItem.toolbar || null
    property Item login_view: Page {

        background: Item {}

        header: Item {
            height: 64

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                spacing: 16
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

            Row {
                anchors.margins: 16
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                ToolButton {
                    onClicked: settings_drawer.open()
                    icon.source: 'qrc:/svg/settings.svg'
                }

                ToolButton {
                    icon.source: 'qrc:/svg/cancel.svg'
                    icon.width: 16
                    icon.height: 16
                    onClicked: {
                        console.log('cancel..')
                        canceled2()
                    }
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

        footer: Item {
            height: 64

            Row {
                visible: wallet.authentication === Wallet.Authenticating || wallet.connection === Wallet.Connecting
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.margins: 16
                spacing: 16

                ProgressBar {
                    property var tor: wallet.events.tor

                    anchors.verticalCenter: parent.verticalCenter
                    from: 0
                    indeterminate: !(tor && tor.progress >= 0 && tor.progress < 100)
                    to: 100
                    value: wallet.events.tor ? wallet.events.tor.progress : 0

                    Behavior on value { SmoothedAnimation {  } }
                }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 16
                    opacity: wallet.events.tor !== undefined && wallet.events.tor.progress > 0 && wallet.events.tor.progress < 100 ? 1 : 0
                    text: wallet.events.tor ? wallet.events.tor.summary : ''

                    Behavior on opacity { OpacityAnimator {} }
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

    property Item wallet_view: WalletView { }

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
