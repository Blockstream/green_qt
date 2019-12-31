import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import './views'

ControllerDialog {
    property string method

    id: controller_dialog
    title: qsTr('id_set_up_twofactor_authentication') + '\n' + qsTr('id_please_provide_your_1s_code').arg(method)
    icon: `assets/svg/2fa_${method}.svg`
    height: 300
    horizontalPadding: 50
    modal: true
    width: 400

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
                TextField {
                    id: data_field
                    Layout.fillWidth: true
                    placeholderText: method
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
                    Layout.alignment: Qt.AlignHCenter
                    text: wallet.config[method].data.split('=')[1]
                }
                QRCode {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: wallet.config[method].data
                }
                Item {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                }
            }
        }
    }
}
