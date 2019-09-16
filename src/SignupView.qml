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
    title: qsTr('CREATE WALLET')

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
        text: qsTr('CANCEL')
        shortcut: StandardKey.Cancel
        onTriggered: root.canceled()
    }

    Action {
        id: back_action
        text: qsTr('BACK')
        enabled: swipe_view.currentIndex > 0
        onTriggered: swipe_view.currentIndex = swipe_view.currentIndex - 1
    }

    Action {
        id: next_action
        text: qsTr('NEXT')
        enabled: swipe_view.currentIndex + 1 < swipe_view.count && swipe_view.currentItem.valid
        onTriggered: swipe_view.currentIndex = swipe_view.currentIndex + 1
    }

    Action {
        id: create_action
        text: qsTr('CREATE')
        enabled: swipe_view.currentIndex + 1 === swipe_view.count && swipe_view.currentItem.valid
        onTriggered: WalletManager.signup(name_field.text, mnemonic, pin_view.pin)
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
            title: qsTr('CHOOSE NETWORK')

            valid: network_group.checkedButton

            Column {
                anchors.centerIn: parent

                ButtonGroup {
                    id: network_group
                    exclusive: true
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
            title: qsTr('SAVE MNEMONIC')

            MnemonicView {
                anchors.centerIn: parent
                mnemonic: root.mnemonic
            }
        }

        OnboardingPage {
            title: qsTr('SET PIN')
            valid: pin_view.valid

            PinView {
                id: pin_view
                focus: true
                anchors.centerIn: parent
            }
        }

        OnboardingPage {
            activeFocusOnTab: false
            title: qsTr('CONFIRM PIN')
            valid: confirm_pin_view.valid && pin_view.pin === confirm_pin_view.pin

            onValidChanged: if (valid && next_action.enabled) next_action.trigger()

            PinView {
                id: confirm_pin_view
                focus: true
                anchors.centerIn: parent
            }
        }

        OnboardingPage {
            title: qsTr('FINISH')
            valid: name_field.text.length > 0

            TextField {
                id: name_field
                anchors.centerIn: parent
            }
        }
    }
}
