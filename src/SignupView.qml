import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import Blockstream.Green 0.1

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

        Pane {

            MnemonicView {
                anchors.centerIn: parent
                property string title: qsTr('SAVE MNEMONIC')
                property bool valid: true
                mnemonic: root.mnemonic
            }
        }

        FocusScope {
            enabled: SwipeView.isCurrentItem
            property string title: qsTr('SET PIN')
            property alias valid: pin_view.valid

            //SwipeView.onIsCurrentItemChanged: if (SwipeView.isCurrentItem) forceActiveFocus(); else pin_view.clear()
            activeFocusOnTab: false
            PinField {
                focus: true
                anchors.fill: parent
                id: pin_view
                //onPinChanged: if (valid) next()
            }
        }

        PinField {
            id: confirm_pin_view
            enabled: SwipeView.isCurrentItem
            property string title: qsTr('CONFIRM PIN')
            //valid: pin_view.pin === confirm_pin_view.pin
        }

        Pane {
            property string title: qsTr('FINISH')
            property bool valid: true
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
