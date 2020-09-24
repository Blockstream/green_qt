import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

Page {
    id: view

    signal restored(Wallet wallet)
    signal canceled()

    RestoreController {
        id: controller
        onFinished: view.restored(wallet);
    }

    Connections {
        target: controller.wallet
        function onAuthenticationChanged() {
            // TODO show error message
            if (controller.wallet.authentication === Wallet.Authenticated) {
                stack_view.push(pin_page)
            }
        }
    }

    StackView {
        id: stack_view
        anchors.centerIn: parent
        clip: true
        implicitWidth: currentItem.implicitWidth
        implicitHeight: currentItem.implicitHeight

        initialItem: network_page
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
                text: 'Connection Settings'
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
                placeholderText: 'host:address'
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

    property Item toolbar: RowLayout {
        ProgressBar {
            Layout.maximumWidth: 64
            indeterminate: true
            opacity: controller.wallet && controller.wallet.authentication === Wallet.Authenticating ? 0.5 : 0
            visible: opacity > 0
            Behavior on opacity {
                SmoothedAnimation {
                    duration: 500
                    velocity: -1
                }
            }
        }
        ToolButton {
            onClicked: settings_drawer.open()
            icon.source: 'qrc:/svg/settings.svg'
        }
        ToolButton {
            icon.source: 'qrc:/svg/cancel.svg'
            icon.width: 16
            icon.height: 16
            onClicked: view.canceled()
        }
    }

    background: Item {}

    footer: Item {
        height: 64

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 16
            Repeater {
                model: stack_view.currentItem.actions
                Button {
                    focus: modelData.focus || false
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
            text: qsTrId('Restore Wallet') + ' - ' + stack_view.currentItem.title
        }
    }

    property Item network_page: NetworkPage {
        subtitle: qsTrId('id_restore_green_wallet')
        actions: []
        onNext: {
            const proxy = proxy_checkbox.checked ? proxy_field.text : '';
            const use_tor = tor_checkbox.checked;
            controller.network = network_page.network;
            controller.wallet.connect(proxy, use_tor);
            settings_drawer.enabled = false;
            stack_view.push(mnemonic_page);
        }
    }

    property Item mnemonic_page: MnemonicEditor {
        title: qsTrId('Insert your green mnemonic')
        actions: [
            Action {
                property bool focus: mnemonic_page.valid
                text: qsTrId('id_continue')
                enabled: mnemonic_page.valid && controller.wallet.authentication === Wallet.Unauthenticated
                onTriggered: {
                    if (mnemonic_page.password) {
                        stack_view.push(password_page)
                    } else {
                        controller.wallet.login(mnemonic_page.mnemonic)
                    }
                }
            }
        ]
    }

    property Item password_page: WizardPage {
        title: qsTrId('id_please_provide_your_passphrase')
        actions: [
            Action {
                id: passphrase_next_action
                text: qsTrId('id_continue')
                enabled: controller.wallet && controller.wallet.authentication === Wallet.Unauthenticated && password_field.text.trim().length > 0
                onTriggered: controller.wallet.login(mnemonic_page.mnemonic, password_field.text.trim())
            }
        ]
        TextField {
            id: password_field
            anchors.centerIn: parent
            implicitWidth: 400
            echoMode: TextField.Password
            onAccepted: passphrase_next_action.trigger()
            placeholderText: qsTrId('id_encryption_passphrase')
        }
    }

    property Item pin_page: WizardPage {
        title: qsTrId('id_set_a_new_pin')
        PinView {
            id: pin_view
            anchors.centerIn: parent
            onValidChanged: if (valid) stack_view.push(pin_verify_page)
        }
    }

    property Item pin_verify_page: WizardPage {
        title: qsTrId('id_verify_your_pin')
        PinView {
            anchors.centerIn: parent
            onPinChanged: {
                if (pin !== pin_view.pin) {
                    clear();
                    ToolTip.show(qsTrId('id_pins_do_not_match_please_try'), 1000);
                } else {
                    controller.wallet.setPin(pin_view.pin);
                    stack_view.push(name_page);
                }
            }
        }
    }

    property Item name_page: ColumnLayout {
        property string title: qsTrId('id_set_wallet_name')
        property list<Action> actions: [
            Action {
                text: qsTrId('id_restore')
                onTriggered: {
                    controller.name = name_field.text.trim();
                    controller.restore()
                }
            }
        ]

        TextField {
            id: name_field
            Layout.minimumWidth: 300
            font.pixelSize: 16
            placeholderText: controller.defaultName
        }
    }
}
