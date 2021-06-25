import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

ControllerDialog {
    id: dialog
    title: qsTrId('id_add_new_account')
    minimumWidth: 200
    controller: CreateAccountController {
        id: create_account_controller
        wallet: dialog.wallet
        onCreated: {
            if (type === '2of3') {
                dialog.push(handler, xpub_done_component)
                closePolicy = Popup.NoAutoClose
            } else {
                dialog.push(handler, doneComponent)
            }
        }
    }

    property Component xpub_done_component: ColumnLayout {
        property Handler handler
        property list<Action> actions: [
            Action {
                text: qsTrId('id_copy_xpub')
                onTriggered: {
                    Clipboard.copy(handler.result.result.recovery_xpub);
                    recovery_xpub_label.ToolTip.show(qsTrId('id_copied_to_clipboard'), 1000);
                }
            },
            Action {
                text: qsTrId('id_ok')
                onTriggered: accept()
            }
        ]
        SectionLabel { text: qsTrId('id_recovery_mnemonic') }
        RowLayout {
            MnemonicView {
                Layout.fillHeight: false
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true
                mnemonic: handler.result.result.recovery_mnemonic.split(' ')
            }
            Spacer {
            }
            QRCode {
                Layout.fillWidth: false
                Layout.alignment: Qt.AlignCenter
                id: qrcode
                implicitHeight: 128
                implicitWidth: 128
                text: handler.result.result.recovery_mnemonic
            }
        }
        SectionLabel { text: qsTrId('id_recovery_xpub') }
        Label {
            id: recovery_xpub_label
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            wrapMode: Label.WrapAnywhere
            text: handler.result.result.recovery_xpub
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Qt.AlignHCenter
            Layout.margins: 16
            wrapMode: Label.WordWrap
            text: qsTrId('id_backup_the_recovery_mnemonic')
            Rectangle {
                color: 'red'
                radius: height/2
                opacity: 0.2
                anchors.fill: parent
                anchors.margins: -8
            }
        }
    }

    doneText: qsTrId("New account created")

    initialItem: StackView {
        id: stack_view
        property var actions: currentItem.actions
        implicitHeight: currentItem.implicitHeight
        implicitWidth: currentItem.implicitWidth

        initialItem: ColumnLayout {
            spacing: 16
            property list<Action> actions: [
                Action {
                    text: qsTrId('id_next')
                    enabled: type_button_group.checkedButton
                    onTriggered: {
                        create_account_controller.type = type_button_group.checkedButton.type;
                        stack_view.push(review_view);
                    }
                }
            ]
            ButtonGroup {
                id: type_button_group
            }
            DescriptiveRadioButton {
                readonly property string type: '2of2'
                visible: !controller.wallet.network.electrum
                text: qsTrId('id_standard_account')
                description: qsTrId('id_standard_accounts_allow_you_to')
                checked: true
                enabled: true
                ButtonGroup.group: type_button_group
                Layout.fillWidth: true
                Layout.maximumWidth: 400
            }
            DescriptiveRadioButton {
                readonly property string type: '2of2_no_recovery'
                visible: !controller.wallet.network.electrum
                text: qsTrId('id_amp_account')
                description: qsTrId('id_amp_accounts_are_only_available')
                enabled: wallet.network.liquid
                ButtonGroup.group: type_button_group
                Layout.maximumWidth: 400
                Layout.fillWidth: true
            }
            DescriptiveRadioButton {
                readonly property string type: '2of3'
                visible: !controller.wallet.network.electrum
                text: qsTrId('id_2of3_account')
                description: qsTrId('id_a_2of3_account_requires_two_out')
                enabled: !wallet.network.liquid
                ButtonGroup.group: type_button_group
                Layout.fillWidth: true
                Layout.maximumWidth: 400
            }
            DescriptiveRadioButton {
                readonly property string type: 'p2sh-p2wpkh'
                visible: controller.wallet.network.electrum
                text: qsTrId('Legacy Account')
                description: qsTrId('BIP49 accounts allow you to segregate funds, and to receive on wrapped segwit addresses, thus ensuring the highest backwards compatibility when receiving funds from anyone on the network.')
                ButtonGroup.group: type_button_group
                Layout.fillWidth: true
                Layout.maximumWidth: 400
            }
            DescriptiveRadioButton {
                readonly property string type: 'p2wpkh'
                visible: controller.wallet.network.electrum
                text: qsTrId('SegWit Account')
                description: qsTrId('BIP84 accounts allow you to segregate your funds, and to receive on bech32 native segwit addresses. This account type ensures cheaper transactions when sending funds, but not all services support bech32 addresses yet.')
                ButtonGroup.group: type_button_group
                Layout.fillWidth: true
                Layout.maximumWidth: 400
            }
        }
    }

    Component {
        id: review_view
        ColumnLayout {
            property list<Action> actions: [
                Action {
                    id: create_action
                    text: qsTrId('id_create')
                    enabled: name_field.text.trim() !== ''
                    onTriggered: {
                        create_action.enabled = false;
                        create_account_controller.name = name_field.text.trim();
                        create_account_controller.create()
                    }
                }
            ]
            spacing: 16
            SectionLabel {
                text: qsTrId('id_account_type')
            }
            Label {
                text: type_button_group.checkedButton.text
            }
            SectionLabel {
                text: qsTrId('id_account_name')
            }
            TextField {
                id: name_field
                Layout.fillWidth: true
            }
        }
    }
}
