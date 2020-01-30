import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import './views'

ControllerDialog {
    property string method

    id: controller_dialog
    title: qsTr('id_set_up_twofactor_authentication')
    icon: `assets/svg/2fa_${method}.svg`
    height: 300
    horizontalPadding: 50
    modal: true
    width: 400
    doneText: qsTr('id_enabled')

    controller: TwoFactorController {
        method: controller_dialog.method
    }

    initialItem: method === 'gauth' ? gauth_component : generic_component

    Component {
        id: generic_component
        WizardPage {
            actions: Action {
                text: qsTr('id_next')
                onTriggered: controller.enable(data_field.text)
            }
            ColumnLayout {
                anchors.fill: parent

                Label {
                    Layout.fillWidth: true
                    text: description
                    wrapMode: Text.WordWrap
                }

                TextField {
                    id: data_field
                    Layout.fillWidth: true
                    placeholderText: placeholder
                }
            }
            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
            }
        }
    }

    Component {
        id: gauth_component
        WizardPage {
            actions: Action {
                text: qsTr('id_next')
                onTriggered: controller.enable(wallet.config[method].data)
            }
            ColumnLayout {
                anchors.fill: parent
                Label {
                    Layout.fillWidth: true
                    text: qsTr('id_scan_the_qr_code_in_google')
                    wrapMode: Text.WordWrap
                }
                QRCode {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: wallet.config[method].data
                }
                Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: wallet.config[method].data.split('=')[1]
                    color: 'green'
                }
                Item {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                }
            }
        }
    }
}
