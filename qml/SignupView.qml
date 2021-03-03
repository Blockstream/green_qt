import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

AbstractDialog {
    id: root
    required property string network
    icon: icons[network]
    title: 'Create Wallet'
    SignupController {
        id: controller
        network: NetworkManager.network(root.network)
        onDone: pushLocation(`/${controller.network.id}/${controller.wallet.id}`)
    }

    closePolicy: Popup.NoAutoClose

    width: 800
    height: 500

    signal close()

    footer: Pane {
        topPadding: 0
        leftPadding: 32
        rightPadding: 32
        bottomPadding: 16
        background: Item {
        }
        contentItem: RowLayout {
            PageIndicator {
                count: 7
                currentIndex: stack_view.depth - 1
                width: 128
            }
            Item {
                Layout.fillWidth: true
                height: 1
            }
            Repeater {
                model: stack_view.currentItem.actions
                Button {
                    action: modelData
                    flat: true
                }
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
        Item {
            Layout.fillWidth: true
            width: 1
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
        Item {
            Layout.fillWidth: true
            width: 1
        }
    }

    property Item name_page: ColumnLayout {
        property list<Action> actions: [
            Action {
                text: qsTrId('id_create')
                onTriggered: {
                    controller.name = name_field.text.trim()
                    const proxy = Settings.useProxy ? Settings.proxyHost + ':' + Settings.proxyPort : ''
                    const use_tor = Settings.useTor
                    const pin = pin_view.pin.value;
                    const wallet = controller.signup(proxy, use_tor, pin);
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
            id: name_field
            width: 300
            font.pixelSize: 16
            placeholderText: controller.defaultName
        }
        Item {
            Layout.fillWidth: true
            width: 1
        }
    }

    property Item creating_page: Item {
        ColumnLayout {
            spacing: 16

            anchors.centerIn: parent
            BusyIndicator {
                Layout.alignment: Qt.AlignCenter
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                text: 'Creating Wallet'
            }
        }
    }
}
