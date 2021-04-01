import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

AbstractDialog {
    required property Network network
    id: self
    icon: icons[network.id]
    title: qsTrId('id_create_new_wallet')

    SignupController {
        id: controller
        network: self.network
        pin: pin_view.pin.value
        name: name_field.text.trim()
    }

    Connections {
        target: controller.wallet
        function onReadyChanged(ready) {
            if (ready) pushLocation(`/${controller.network.id}/${controller.wallet.id}`)
        }
    }

    Connections {
        target: controller.wallet ? controller.wallet.session : null
        function onActivityCreated(activity) {
            if (activity instanceof SessionTorCircuitActivity) {
                session_tor_cirtcuit_view.createObject(activities_row, { activity })
            } else if (activity instanceof SessionConnectActivity) {
                session_connect_view.createObject(activities_row, { activity })
            }
        }
    }

    closePolicy: Popup.NoAutoClose

    width: 800
    height: 500

    footer: DialogFooter {
        Pane {
            Layout.minimumHeight: 48
            background: null
            padding: 0
            contentItem: RowLayout {
                id: activities_row
            }
        }
        PageIndicator {
            count: 7
            currentIndex: stack_view.depth - 1
            width: 128
        }
        HSpacer {}
        Repeater {
            model: stack_view.currentItem.actions
            GButton {
                action: modelData
                large: true
            }
        }
    }

    contentItem: StackView {
        id: stack_view
        focus: true
        clip: true
        initialItem: welcome_page
    }

    property Item welcome_page: WelcomePage {
        onNext: stack_view.push(mnemonic_page)
    }

    property Item mnemonic_page: MnemonicPage {
        mnemonic: controller.mnemonic
        onBack: {
            stack_view.pop();
        }
        onNext: {
            quiz_page.reset()
            stack_view.push(quiz_page);
        }
    }

    property Item quiz_page: MnemonicQuizPage {
        mnemonic: controller.mnemonic
        onBack: stack_view.pop()
        onNext: stack_view.push(set_pin_page)
    }

    property Item set_pin_page: ColumnLayout {
        property list<Action> actions

        implicitWidth: pin_view.implicitWidth
        implicitHeight: pin_view.implicitHeight
        spacing: 16
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: qsTrId('id_create_a_pin_to_access_your')
            font.pixelSize: 20
        }
        PinView {
            Layout.alignment: Qt.AlignHCenter
            id: pin_view
            focus: true
            onPinChanged: {
                if (pin.valid) {
                    stack_view.push(verify_pin_page);
                }
            }
        }
        HSpacer {
        }
    }

    property Item verify_pin_page: ColumnLayout {
        property list<Action> actions
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: qsTrId('id_verify_your_pin')
            font.pixelSize: 20
        }
        PinView {
            Layout.alignment: Qt.AlignHCenter
            id: verify_pin_view
            focus: true
            onPinChanged: {
                if (!pin.valid) return;
                if (pin_view.pin.value !== pin.value) return clear();
                stack_view.push(name_page);
            }
        }
        HSpacer {
        }
    }

    property Item name_page: ColumnLayout {
        property list<Action> actions: [
            Action {
                text: qsTrId('id_create')
                onTriggered: {
                    controller.active = true
                    stack_view.push(creating_page)
                }
            }
        ]

        implicitWidth: name_field.width
        implicitHeight: name_field.implicitHeight

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: qsTrId('id_set_wallet_name')
            font.pixelSize: 20
        }
        TextField {
            Layout.alignment: Qt.AlignHCenter
            Layout.minimumWidth: 300
            id: name_field
            font.pixelSize: 16
            placeholderText: controller.defaultName
        }
        HSpacer {
        }
    }

    property Item creating_page: ColumnLayout {
        spacing: 16
        VSpacer {}
        BusyIndicator {
            Layout.alignment: Qt.AlignCenter
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            text: {
                const count = controller.wallet ? controller.wallet.activities.length : 0
                if (count > 0) {
                    const activity = controller.wallet.activities[count - 1]
                    if (activity instanceof WalletRefreshAssets) {
                        return qsTrId('id_loading_assets')
                    }
                }
                return qsTrId('id_creating_wallet')
            }
        }
        VSpacer {}
    }
}
