import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import './views'
import './views/onboarding'

Page {
    property var mnemonic: WalletManager.generateMnemonic()

    id: root

    background: Item {}

    header: Item {
        height: 64

        Row {
            visible: !!network_page.network
            anchors.margins: 16
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 16
            Image {
                anchors.verticalCenter: parent.verticalCenter
                source: network_page.network ? icons[network_page.network.id] : ''
                sourceSize.height: 32
                sourceSize.width: 32
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 24
                text: network_page.network ? network_page.network.name : ''
            }
        }

        Label {
            anchors.centerIn: parent
            font.pixelSize: 24
            text: stack_layout.currentItem.title
        }

        Row {
            anchors.margins: 16
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            ToolButton {
                onClicked: settings_drawer.open()
                icon.source: 'assets/svg/settings.svg'
            }

            ToolButton {
                action: cancel_action
                icon.source: 'assets/svg/cancel.svg'
                icon.width: 16
                icon.height: 16
            }
        }
    }

    footer: Item {
        height: 64

        PageIndicator {
            anchors.centerIn: parent
            count: stack_layout.count
            currentIndex: stack_layout.currentIndex
            width: 128
            Layout.fillWidth: true
            Layout.margins: 16
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 16
            Repeater {
                model: stack_layout.currentItem.actions
                Button {
                    action: modelData
                    flat: true
                    Layout.rightMargin: 16
                    Layout.bottomMargin: 16
                    Layout.topMargin: 16
                    Layout.minimumWidth: 128
                }
            }
        }
    }

    Drawer {
        id: settings_drawer
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
                text: qsTr('id_connect_through_a_proxy')
            }
            TextField {
                id: proxy_field
                Layout.leftMargin: 32
                Layout.fillWidth: true
                enabled: proxy_checkbox.checked
                placeholderText: 'host:address'
            }
            CheckBox {
                id: tor_checkbox
                text: qsTr('id_connect_with_tor')
            }
            Item {
               Layout.fillWidth: true
               Layout.fillHeight: true
            }
        }
    }

    Action {
        id: cancel_action
        shortcut: StandardKey.Cancel
        onTriggered: stack_view.pop()
    }

    Action {
        id: back_action
        enabled: stack_layout.currentIndex > 0
        onTriggered: stack_layout.currentIndex = stack_layout.currentIndex - 1
    }

    Action {
        id: next_action
        enabled: stack_layout.currentIndex < stack_layout.count - 1
        onTriggered: stack_layout.currentIndex = stack_layout.currentIndex + 1
    }

    StackLayout {
        id: stack_layout
        property Item currentItem: children[currentIndex]
        currentIndex: 0
        focus: true

        anchors.fill: parent
        anchors.margins: 32

        Item {
            property string title: qsTrId('Welcoming to Creation Process')
            property list<Action> actions: [
                Action {
                    text: qsTrId('id_continue')
                    enabled: welcome_page.agreeWithTermsOfService
                    onTriggered: next_action.trigger()
                }
            ]

            WelcomePage {
                id: welcome_page
            }
        }

        Item {
            property string title: qsTrId('id_choose_your_network')
            property list<Action> actions: [
                Action {
                    text: qsTrId('id_back')
                    onTriggered: back_action.trigger()
                }
            ]

            NetworkPage {
                id: network_page
                onNetworkChanged: {
                    if (network) next_action.trigger();
                }
            }
        }

        Item {
            property string title: qsTrId('id_save_your_mnemonic')
            property list<Action> actions: [
                Action {
                    text: qsTrId('id_back')
                    onTriggered: {
                        back_action.trigger();
                        network_page.network = null;
                    }
                },
                Action {
                    text: qsTrId('id_continue')
                    onTriggered: {
                        mnemonic_quiz_view.reset();
                        next_action.trigger();
                    }
                }
            ]

            MnemonicView {
                anchors.centerIn: parent
                mnemonic: root.mnemonic
            }
        }

        Item {
            property string title: qsTrId('Check your backup')
            property list<Action> actions: [
                Action {
                    text: qsTrId('id_back')
                    onTriggered: back_action.trigger()
                }
            ]

            MnemonicQuizView {
                id: mnemonic_quiz_view
                anchors.centerIn: parent
                onCompleteChanged: {
                    if (complete) {
                        next_action.trigger();
                    }
                }
            }
        }

        Page {
            title: qsTr('id_create_a_pin_to_access_your')

            property list<Action> actions

            PinView {
                id: pin_view
                focus: true
                anchors.centerIn: parent
                onPinChanged: if (valid) next_action.trigger()
            }
        }

        Page {
            activeFocusOnTab: false
            title: qsTr('id_verify_your_pin')
            property list<Action> actions

            PinView {
                focus: true
                anchors.centerIn: parent
                onPinChanged: if (valid) {
                    if (pin_view.pin === pin) next_action.trigger()
                    else clear()
                }
            }
        }

        Page {
            title: qsTrId('Set wallet name')

            property list<Action> actions: [
                Action {
                    enabled: name_field.text.trim().length > 0
                    text: qsTr('id_create')
                    onTriggered: {
                        currentWallet = WalletManager.signup(proxy_checkbox.checked ? proxy_field.text : '', tor_checkbox.checked, network_page.network, name_field.text, mnemonic, pin_view.pin)
                        stack_view.pop()
                    }
                }
            ]

            TextField {
                anchors.centerIn: parent
                id: name_field
                width: 300
                font.pixelSize: 16
                placeholderText: qsTrId('My %1 Wallet').arg(network_page.network ? network_page.network.name : '')
            }
        }
    }
}
