import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import Blockstream.Green 0.1
import './views'
import './views/onboarding'

Page {
    property var mnemonic: wallet.generateMnemonic()
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
        onTriggered: wallet.signup(name_field.text, mnemonic, pin_view.pin)
    }

    SwipeView {
        id: swipe_view
        activeFocusOnTab: false
        clip: true
        focus: true
        interactive: false

        anchors.fill: parent

        WelcomePage {}

        ServiceTermsPage {}

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

            Wallet {
                id: wallet
            }

            TextField {
                id: name_field
                anchors.centerIn: parent
            }
        }
    }
}
