import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import Blockstream.Green 0.1
import './views'

ColumnLayout {
    id: root

    signal canceled()

    function back() {
        if (swipe_view.currentIndex > 0) {
            swipe_view.currentIndex = swipe_view.currentIndex - 1
        }
    }

    function next() {
        if (swipe_view.currentIndex + 1 < swipe_view.count) {
            swipe_view.currentIndex = swipe_view.currentIndex + 1
        }
    }

    property var mnemonic: wallet.generateMnemonic()

    Label {
        Layout.fillWidth: true
        text: swipe_view.currentItem.title
    }


    property string title: qsTr('Create Wallet')

    Action {
        id: cancel_action
        shortcut: StandardKey.Cancel
        onTriggered: root.canceled()
    }

    SwipeView {
        id: swipe_view

        clip: true
        focus: true
        activeFocusOnTab: false
        Layout.fillWidth: true
        Layout.fillHeight: true

        interactive: false

        OnboardingView {
            enabled: SwipeView.isCurrentItem
            property string title: qsTr('WELCOME')
            property bool valid: true
        }

        ServiceTermsView {
            id: xx
            focus: true
            enabled: SwipeView.isCurrentItem
            property string title: qsTr('TERM OF SERVICE')
            property bool valid: accepted
        }

        Page {
            property bool valid: true

            title: qsTr('SAVE MNEMONIC')

            MnemonicView {
                anchors.centerIn: parent
                mnemonic: root.mnemonic
            }
        }

        Page {
            property alias valid: pin_view.valid

            enabled: SwipeView.isCurrentItem
            title: qsTr('SET PIN')
            activeFocusOnTab: false

            PinView {
                id: pin_view
                focus: true
                anchors.centerIn: parent
                //onPinChanged: if (valid) next()
            }
        }


        Page {
            property alias valid: pin_view.valid

            enabled: SwipeView.isCurrentItem
            title: qsTr('CONFIRM PIN')
            activeFocusOnTab: false

            PinView {
                id: confirm_pin_view
                focus: true
                anchors.centerIn: parent
            }
        }

        Page {
            property bool valid: true

            title: qsTr('FINISH')

            Wallet {
                id: wallet
            }

            Column {
                TextField {
                    id: name_field
                }

                Button {
                    text: "CREATE"
                    onClicked: wallet.signup(name_field.text, mnemonic, pin_view.pin)
                }
            }
        }
    }

    RowLayout {
        PageIndicator {
            Layout.fillWidth: true
            currentIndex: swipe_view.currentIndex
            count: swipe_view.count
        }
        FlatButton {
            text: qsTr("CANCEL")
            action: cancel_action
        }
        FlatButton {
            text: qsTr("BACK")
            enabled: swipe_view.currentIndex > 0
            onClicked: back()
        }
        FlatButton {
            text: qsTr("NEXT")
            enabled: swipe_view.currentIndex + 1 < swipe_view.count && swipe_view.currentItem.valid
            onClicked: next()
        }
    }
}
