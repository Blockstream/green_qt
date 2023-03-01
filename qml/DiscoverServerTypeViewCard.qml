import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS

Button {
    required property string server_type
    required property string title
    property var icons
    property alias busy: controller.busy
    property alias active: controller.active
    property alias wallet: controller.wallet
    property alias noErrors: controller.noErrors

    id: self
    Layout.alignment: Qt.AlignTop
    Layout.minimumHeight: 250
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
            Layout.fillHeight: false
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
                Layout.preferredWidth: 0
                text: self.title
                font.bold: true
                font.pixelSize: 20
            }
        }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Loader {
                anchors.centerIn: parent
                Layout.preferredWidth: 100
                Layout.preferredHeight: 100
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
        }
        FixedErrorBadge {
            Layout.alignment: Qt.AlignCenter
            pointer: false
            error: switch (controller.errors.password) {
                case 'mismatch': return qsTrId('id_error_passphrases_do_not_match')
            }
        }
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            RowLayout {
                anchors.fill: parent
                Label {
                    visible: !controller.wallet && !controller.busy && !controller.valid && controller.noErrors
                    text: qsTrId('id_wallet_not_found')
                }
                Label {
                    visible: controller.valid
                    text: qsTrId('id_wallet_found')
                }
                Label {
                    visible: controller.wallet && controller.wallet.hasPinData
                    text: qsTrId('id_wallet_already_restored') + ' - ' + controller.wallet.name
                }
                HSpacer {
                }
                GButton {
                    text: 'Restore anyway'
                    visible: self.server_type === 'electrum' && !controller.valid && !controller.wallet && advanced_checkbox.checked
                    onClicked: navigation.controller = controller
                }
                GButton {
                    text: controller.wallet && !controller.hasPinData
                        ? qsTrId('id_create_a_pin_to_access_your')
                        : qsTrId('id_restore')
                    visible: controller.valid
                    onClicked: navigation.controller = controller
                }
            }
        }
    }

    RestoreController {
        id: controller
        network: {
            const network = navigation.param.network || ''
            return NetworkManager.networkWithServerType(network, self.server_type)
        }
        type: navigation.param.type || ''
        mnemonic: navigation.param.mnemonic.split(',')
        password: navigation.param.password || ''
        pin: navigation.param.pin || ''
        active: self.visible
        onFinished: {
            Analytics.recordEvent('wallet_restore', AnalyticsJS.segmentationSession(controller.wallet))
            navigation.set({ view: controller.wallet.network.key, wallet: controller.wallet.id })
        }
    }
}
