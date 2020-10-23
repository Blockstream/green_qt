import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

Page {
    SignupController {
        id: controller
        network: network_page.network
    }

    signal close()

    id: root

    property Item toolbar: RowLayout {
        ToolButton {
            onClicked: settings_drawer.open()
            icon.source: 'qrc:/svg/settings.svg'
        }
        ToolButton {
            onClicked: close()
            icon.source: 'qrc:/svg/cancel.svg'
            icon.width: 16
            icon.height: 16
        }
    }

    background: Item {}

    header: Item {
        height: 64

        Label {
            id: network_label
            background: Item {
                Image {
                    anchors.verticalCenter: parent.verticalCenter
                    source: network_page.network ? icons[network_page.network.id] : ''
                    sourceSize.height: 32
                    sourceSize.width: 32
                }
            }
            leftPadding: 40
            anchors.margins: 16
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 24
            text: network_page.network ? network_page.network.name : ''
            opacity: !!network_page.network ? 1 : 0
            Behavior on opacity { OpacityAnimator { } }
        }

        Label {
            anchors.baseline: network_label.baseline
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - network_label.width * 2 - 64
            font.pixelSize: 24
            wrapMode: Text.WordWrap
            horizontalAlignment: Label.AlignHCenter
            text: stack_view.currentItem.title
        }
    }

    footer: Item {
        height: 64

        PageIndicator {
            anchors.centerIn: parent
            count: 7
            currentIndex: stack_view.depth - 1
            width: 128
            Layout.fillWidth: true
            Layout.margins: 16
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 16
            Repeater {
                model: stack_view.currentItem.actions
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
        interactive: position > 0
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
                text: qsTrId('id_advanced_network_settings')
                font.pixelSize: 18
                Layout.margins: 16
            }

            CheckBox {
                id: proxy_checkbox
                text: qsTrId('id_connect_through_a_proxy')
            }
            TextField {
                id: proxy_field
                Layout.leftMargin: 32
                Layout.fillWidth: true
                enabled: proxy_checkbox.checked
                placeholderText: 'host:port'
            }
            CheckBox {
                id: tor_checkbox
                text: qsTrId('id_connect_with_tor')
            }
            Item {
               Layout.fillWidth: true
               Layout.fillHeight: true
            }
        }
    }

    StackView {
        id: stack_view
        focus: true
        clip: true
        anchors.centerIn: parent
        implicitWidth: currentItem.implicitWidth
        implicitHeight: currentItem.implicitHeight
        initialItem: welcome_page
    }

    property Item welcome_page: WelcomePage {
        onNext: stack_view.push(network_page)
    }

    property Item network_page: NetworkPage {
        subtitle: qsTrId('id_create_a_wallet_for_bitcoin')
        onBack: stack_view.pop()
        onNext: stack_view.push(mnemonic_page)
    }

    property Item mnemonic_page: MnemonicPage {
        mnemonic: controller.mnemonic
        onBack: {
            network_page.network = null;
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

    property Item set_pin_page: Item {
        property string title: qsTrId('id_create_a_pin_to_access_your')
        property list<Action> actions

        implicitWidth: pin_view.implicitWidth
        implicitHeight: pin_view.implicitHeight

        PinView {
            id: pin_view
            focus: true
            anchors.centerIn: parent
            onPinChanged: {
                if (valid) {
                    stack_view.push(verify_pin_page);
                }
            }
        }
    }

    property Item verify_pin_page: Item {
        property string title: qsTrId('id_verify_your_pin')
        property list<Action> actions

        activeFocusOnTab: false
        implicitWidth: verify_pin_view.implicitWidth
        implicitHeight: verify_pin_view.implicitHeight

        PinView {
            id: verify_pin_view
            focus: true
            anchors.centerIn: parent
            onPinChanged: {
                if (!valid) return;
                if (pin_view.pin !== pin) return clear();
                stack_view.push(name_page);
            }
        }
    }

    property Item name_page: Item {
        property string title: qsTrId('id_set_wallet_name')
        property list<Action> actions: [
            Action {
                text: qsTrId('id_create')
                onTriggered: {
                    controller.name = name_field.text.trim()
                    const proxy = proxy_checkbox.checked ? proxy_field.text : '';
                    const use_tor = tor_checkbox.checked;
                    const pin = pin_view.pin;
                    const wallet = controller.signup(proxy, use_tor, pin);
                    close();
                    switchToWallet(wallet);
                }
            }
        ]

        implicitWidth: name_field.width
        implicitHeight: name_field.implicitHeight

        TextField {
            anchors.centerIn: parent
            id: name_field
            width: 300
            font.pixelSize: 16
            placeholderText: controller.defaultName
        }
    }
}
