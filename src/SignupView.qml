import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import Blockstream.Green 0.1
import './views'
import './views/onboarding'

Page {
    property var mnemonic: WalletManager.generateMnemonic()
    signal canceled()

    id: root
    title: qsTr('id_create_new_wallet')

    footer: RowLayout {
        PageIndicator {
            Layout.fillWidth: true
            currentIndex: swipe_view.currentIndex
            count: swipe_view.count
        }

        FlatButton {
            action: cancel_action
        }

        FlatButton {
            action: back_action
        }

        FlatButton {
            action: next_action
            visible: swipe_view.currentIndex + 1 < swipe_view.count
            enabled: swipe_view.currentItem.next
        }

        FlatButton {
            action: create_action
            visible: swipe_view.currentIndex + 1 === swipe_view.count
        }
    }

    header: Label {
        text: swipe_view.currentItem.title
    }

    Action {
        id: cancel_action
        text: qsTr('id_cancel')
        shortcut: StandardKey.Cancel
        onTriggered: root.canceled()
    }

    Action {
        id: back_action
        text: qsTr('BACK') // TODO: add string
        onTriggered: swipe_view.currentIndex = swipe_view.currentIndex - 1
    }

    Action {
        id: next_action
        text: qsTr('id_next')
        onTriggered: swipe_view.currentIndex = swipe_view.currentIndex + 1
    }

    Action {
        id: create_action
        text: qsTr('id_create')
        onTriggered: currentWallet = WalletManager.signup(network_group.checkedButton.network.network, name_field.text, mnemonic, pin_view.pin)
    }

    SwipeView {
        id: swipe_view
        activeFocusOnTab: false
        clip: true
        currentIndex: 2
        focus: true
        interactive: false

        anchors.fill: parent

        WelcomePage {}

        ServiceTermsPage {}

        OnboardingPage {
            title: qsTr('id_choose_your_network')

            next: false

            Column {
                anchors.centerIn: parent

                ButtonGroup {
                    id: network_group
                    exclusive: true
                    onCheckedButtonChanged: next_action.trigger()
                }

                Repeater {
                    model: {
                        const result = []
                        const networks = WalletManager.networks()
                        for (const id of networks.all_networks) {
                            const network = networks[id]
                            if (!network.development) result.push(network)
                        }
                        return result
                    }

                    RadioButton {
                        property var network: modelData
                        text: network.name.toUpperCase()
                        ButtonGroup.group: network_group
                    }
                }
            }
        }

        OnboardingPage {
            title: qsTr('id_save_your_mnemonic')

            MnemonicView {
                anchors.centerIn: parent
                mnemonic: root.mnemonic
            }
        }

        OnboardingPage {
            title: qsTr('id_create_a_pin_to_access_your')
            next: false

            PinView {
                id: pin_view
                focus: true
                anchors.centerIn: parent
                onPinChanged: if (valid) next_action.trigger()
            }
        }

        OnboardingPage {
            activeFocusOnTab: false
            title: qsTr('id_verify_your_pin')
            next: false

            PinView {
                id: confirm_pin_view
                focus: true
                anchors.centerIn: parent
                onPinChanged: if (valid) {
                    if (pin_view.pin === pin) next_action.trigger()
                    else confirm_pin_view.clear()
                }
            }
        }

        OnboardingPage {
            title: qsTr('id_done')
            next: false

            TextField {
                id: name_field
                anchors.centerIn: parent
            }
        }
    }
}
