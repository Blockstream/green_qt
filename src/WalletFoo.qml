import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

StackView {

    id: wallet_stack_view

    property Wallet wallet

    initialItem: Page {

        Column {
            spacing: 16
            anchors.margins: 32
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom

            Label {
                visible: wallet.events.tor !== undefined && wallet.events.tor.progress > 0 && wallet.events.tor.progress < 100
                anchors.horizontalCenter: parent.horizontalCenter
                text: wallet.events.tor ? wallet.events.tor.summary : ''
                font.family: dinpro.name
                font.pixelSize: 16
            }

            ProgressBar {
                anchors.horizontalCenter: parent.horizontalCenter
                from: 0
                to: 100
                value: wallet.events.tor ? wallet.events.tor.progress : 0

                visible: wallet.status & Wallet.Working

                property var tor: wallet.events.tor
                indeterminate: !(tor && tor.progress >= 0 && tor.progress < 100)

                Behavior on value {
                    SmoothedAnimation {  }
                }
            }
        }

        Column {
            spacing: 32
            anchors.centerIn: parent

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: wallet.name
                font.family: dinpro.name
                font.pixelSize: 32
            }

            StackView {
                id: stack_view
                anchors.horizontalCenter: parent.horizontalCenter
                clip: true
                implicitWidth: currentItem.implicitWidth
                implicitHeight: currentItem.implicitHeight

                Behavior on width {
                    SmoothedAnimation { }
                }

                Behavior on height {
                    SmoothedAnimation { }
                }

                initialItem: Column {
                    padding: 32

                    FlatButton {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: qsTr('id_log_in')
                        onClicked: {
                            stack_view.push(login_view)
                            wallet.connect()
                        }
                    }

                    Item {
                        width: 1
                        height: 32
                    }

                    CheckBox {
                        anchors.horizontalCenter: parent.horizontalCenter
                        id: proxy_checkbox
                        text: qsTr('id_connect_through_a_proxy')
                    }

                    ColumnLayout {
                        clip: true
                        height: proxy_checkbox.checked ? implicitHeight : 0
                        anchors.horizontalCenter: parent.horizontalCenter

                        Behavior on height {
                            SmoothedAnimation { }
                        }

                        TextField {
                            id: proxy_host_field
                            enabled: proxy_checkbox.checked
                            placeholderText: qsTr('id_socks5_hostname')
                        }

                        TextField {
                            id: proxy_port_field
                            enabled: proxy_checkbox.checked
                            placeholderText: qsTr('id_socks5_port')
                        }
                    }

                    CheckBox {
                        id: tor_checkbox
                        text: qsTr('id_connect_with_tor')
                        checked: true
                    }
                }
            }
        }
    }

    Component {
        id: login_view
        LoginView { }
    }

    Component {
        id: wallet_view
        WalletView { }
    }
}
