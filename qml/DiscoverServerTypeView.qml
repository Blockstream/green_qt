import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.15
import QtQml 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQml.Models 2.0

Page {
    id: self
    background: null
    contentItem: RowLayout {
        spacing: 24
        Card {
            id: singlesig_card
            server_type: 'electrum'
            icons: ['qrc:/svg/singleSig.svg']
            title: qsTrId('id_singlesig')
            visible: navigation.param.type !== 'amp' && (navigation.param.password || '') === ''
        }
        Card {
            id: multisig_card
            server_type: 'green'
            icons: ['qrc:/svg/multi-sig.svg']
            title: qsTrId('id_multisig_shield')
        }
    }
    footer: RowLayout {
        spacing: constants.s1
        GButton {
            text: qsTrId('id_back')
            onClicked: navigation.pop()
        }
        HSpacer {
        }
        CheckBox {
            id: advanced_checkbox
            visible: singlesig_card.active && singlesig_card.noErrors && multisig_card.noErrors
            enabled: !(singlesig_card.busy || multisig_card.busy) && !(singlesig_card.valid && multisig_card.valid) && !(multisig_card.wallet && singlesig_card.wallet)
            text: qsTrId('id_show_advanced_options')
        }
    }

    component Card: Button {
        id: self
        required property string server_type
        //required property string type
        required property string title
        property var icons
        property alias busy: controller.busy
        property alias active: controller.active
        property alias wallet: controller.wallet
        property alias noErrors: controller.noErrors
        RestoreController {
            id: controller
            network: {
                const network = navigation.param.network || ''
                //const server_type = navigation.param.type === 'amp' ? 'green' : (navigation.param.server_type || '')
                return NetworkManager.networkWithServerType(network, self.server_type)
            }
            type: navigation.param.type || ''
            mnemonic: navigation.param.mnemonic.split(',')
            password: navigation.param.password || ''
            pin: navigation.param.pin || ''
            active: self.visible && (server_type !== 'electrum' || !Settings.useTor)
        }

        Layout.alignment: Qt.AlignTop
        Layout.minimumWidth: 405
        //Layout.fillHeight: true
        Layout.fillWidth: true

        padding: 24
        background: Rectangle {
            border.width: 1
            border.color: Qt.rgba(0, 0, 0, 0.3)
            radius: 8
            color: Qt.rgba(1, 1, 1, 0.02)
        }
        contentItem: ColumnLayout {
            spacing: 12
            RowLayout {
                spacing: 12
                Repeater {
                    model: self.icons
                    delegate: Image {
                        opacity: self.enabled ? 1 : 0.5
                        source: modelData
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                    }
                }
                Label {
                    Layout.fillWidth: true
                    text: self.title
                    font.bold: true
                    font.pixelSize: 20
                }
            }
            VSpacer {
            }
            TorUnavailableWithElectrumWarning {
                Layout.alignment: Qt.AlignHCenter
                network: controller.network
                visible: active
            }
            Loader {
                Layout.alignment: Qt.AlignCenter
                active: controller.wallet
                visible: active
                sourceComponent: ColumnLayout {
                    Layout.fillHeight: false
                    spacing: constants.s1
                    Label {
                        Layout.alignment: Qt.AlignCenter
                        text: qsTrId('id_wallet_already_restored')
                    }
                    Label {
                        Layout.alignment: Qt.AlignCenter
                        text: controller.wallet.name
                    }
                }
            }
            Loader {
                Layout.alignment: Qt.AlignCenter
                active: controller.busy
                visible: active
                sourceComponent: ColumnLayout {
                    Layout.fillHeight: false
                    spacing: constants.s1
                    BusyIndicator {
                        Layout.alignment: Qt.AlignCenter
                        running: true
                    }
                    Label {
                        Layout.alignment: Qt.AlignCenter
                        text: qsTrId('id_looking_for_wallets')
                    }
                }
            }
            FixedErrorBadge {
                Layout.alignment: Qt.AlignCenter
                pointer: false
                error: switch (controller.errors.password) {
                    case 'mismatch': return qsTrId('id_error_passphrases_do_not_match')
                }
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                visible: !controller.wallet && !controller.busy && !controller.valid && controller.noErrors
                text: qsTrId('id_wallet_not_found')
            }
            RowLayout {
                Layout.fillHeight: false
                visible: !controller.wallet && !controller.busy && controller.active
                Label {
                    visible: controller.valid
                    text: qsTrId('id_wallet_found')
                }
                HSpacer {
                }
                GButton {
                    text: 'Restore anyway'
                    visible: !controller.valid && advanced_checkbox.checked && controller.network.electrum
                    onClicked: navigation.controller = controller
                }
                GButton {
                    text: qsTrId('id_restore')
                    visible: controller.valid
                    onClicked: navigation.controller = controller
                }
            }
        }
    }
}
