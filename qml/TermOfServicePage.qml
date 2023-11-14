import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    signal addWallet(string deployment)
    signal useDevice(string deployment)

    id: self
    footer: Pane {
        background: null
        padding: 60
        contentItem: ColumnLayout {
            DeploymentSelector {
                id: deployment_selector
                visible: Settings.enableTestnet
            }
        }
    }
    contentItem: ColumnLayout {
        spacing: 0
        VSpacer {
        }
        Image {
            Layout.alignment: Qt.AlignCenter
            source: 'qrc:/svg2/blockstream_green.svg'
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 20
            color: '#FFF'
            font.family: 'SF Compact'
            font.pixelSize: 30
            font.weight: 656
            horizontalAlignment: Label.AlignHCenter
            text: qsTrId('id_simple__secure_selfcustody')
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.maximumWidth: 325
            Layout.topMargin: 10
            font.family: 'SF Compact Display'
            font.pixelSize: 14
            font.weight: 400
            horizontalAlignment: Label.AlignHCenter
            opacity: 0.6
            text: qsTrId('id_everything_you_need_to_take')
            wrapMode: Label.WordWrap
        }
        PrimaryButton {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.maximumWidth: 325
            Layout.topMargin: 50
            enabled: tos_check_box.checked
            text: qsTrId('id_add_wallet')
            onClicked: self.addWallet(deployment_selector.deployment)
        }
        RegularButton {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.maximumWidth: 325
            Layout.topMargin: 10
            Layout.bottomMargin: 10
            enabled: tos_check_box.checked
            text: qsTrId('id_use_hardware_device')
            onClicked: self.useDevice(deployment_selector.deployment)
        }
        RowLayout {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: false
            Layout.fillHeight: false
            Layout.topMargin: 20
            spacing: 10
            CheckBox {
                id: tos_check_box
                Layout.alignment: Qt.AlignCenter
                bottomInset: 0
                topInset: 0
                leftInset: 0
                rightInset: 0
                checked: false
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                font.family: 'SF Compact Display'
                font.pixelSize: 14
                font.weight: 600
                textFormat: Text.RichText
                text: {
                    const terms = new RegExp('(' + qsTrId('id_terms_of_service') + ')', 'gi')
                    const privacy = new RegExp('(' + qsTrId('id_privacy_policy') + ')', 'gi')
                    return qsTrId('id_i_agree_to_the_terms_of_service')
                        .replace(terms, UtilJS.link('https://blockstream.com/green/terms/', '$1'))
                        .replace(privacy, UtilJS.link('https://blockstream.com/green/privacy/', '$1'))
                }
                onLinkActivated: (link) => { Qt.openUrlExternally(link) }
            }
        }
        VSpacer {
        }
    }
}
