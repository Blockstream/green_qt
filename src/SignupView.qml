import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
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
        onTriggered: currentWallet = WalletManager.signup(proxy_checkbox.checked ? proxy_field.text : '', tor_checkbox.checked, network_page.network, name_field.text, mnemonic, pin_view.pin)
    }

    SwipeView {
        id: swipe_view
        activeFocusOnTab: false
        clip: true
        currentIndex: 0
        focus: true
        interactive: false

        anchors.fill: parent

        WelcomePage {}

        ServiceTermsPage {}

        Page {
            property bool next: true
            Column {
                anchors.centerIn: parent
                CheckBox {
                    id: proxy_checkbox
                    text: qsTr('id_connect_through_a_proxy')
                }
                TextField {
                    id: proxy_field
                    x: 48
                    enabled: proxy_checkbox.checked
                    placeholderText: 'host:address'
                }
                CheckBox {
                    id: tor_checkbox
                    text: qsTr('id_connect_with_tor')
                }
            }
        }

        NetworkPage {
            id: network_page
            accept: next_action
        }

        WizardPage {
            title: qsTr('id_save_your_mnemonic')

            MnemonicView {
                anchors.centerIn: parent
                mnemonic: root.mnemonic
            }
        }

        WizardPage {
            title: qsTr('id_create_a_pin_to_access_your')
            next: false

            PinView {
                id: pin_view
                focus: true
                anchors.centerIn: parent
                onPinChanged: if (valid) next_action.trigger()
            }
        }

        WizardPage {
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

        WizardPage {
            title: qsTr('id_done')
            next: false

            TextField {
                id: name_field
                anchors.centerIn: parent
            }
        }
    }
}
