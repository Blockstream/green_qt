import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

MainPage {
    signal done
    id: self
    background: null
    footer: null
    header: null
    padding: 60
    contentItem: ColumnLayout {
        spacing: 10
        VSpacer {
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            color: '#FFF'
            font.pixelSize: 35
            font.weight: 656
            text: 'Help Us Improve'
            wrapMode: Label.WordWrap
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.maximumWidth: 550
            Layout.topMargin: 10
            color: '#FFF'
            font.pixelSize: 14
            font.weight: 400
            horizontalAlignment: Label.AlignHCenter
            text: qsTrId('id_if_you_agree_green_will_collect').replace('Green', 'Blockstream App')
            wrapMode: Label.WordWrap
        }
        ColumnLayout {
            Layout.alignment: Qt.AlignCenter
            Layout.bottomMargin: 20
            Layout.topMargin: 20
            Layout.maximumWidth: 400
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.topMargin: 20
                font.bold: true
                text: qsTrId('id_whats_collected')
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: "• " + qsTrId('id_page_visits_button_presses')
                wrapMode: Label.WordWrap
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: "• " + qsTrId('id_os__app_version_loading_times')
                wrapMode: Label.WordWrap
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.topMargin: 20
                font.bold: true
                text: qsTrId('id_whats_not_collected')
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: "• " + qsTrId('id_recovery_phrases_key_material')
                wrapMode: Label.WordWrap
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: "• " + qsTrId('id_user_contact_info_ip_address')
                wrapMode: Label.WordWrap
            }
            LinkButton {
                Layout.alignment: Qt.AlignCenter
                Layout.topMargin: 20
                text: qsTrId('id_learn_more')
                onClicked: Qt.openUrlExternally('https://help.blockstream.com/hc/en-us/articles/5988514431897')
            }
        }
        RowLayout {
            Layout.fillWidth: false
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 20
            spacing: 20
            RegularButton {
                text: qsTrId('id_dont_collect_data')
                onClicked: {
                    Settings.analytics = 'disabled'
                    self.done()
                }
            }
            PrimaryButton {
                text: qsTrId('id_allow_collection')
                onClicked: {
                    Settings.analytics = 'enabled'
                    self.done()
                }
            }
        }
        VSpacer {
        }
    }
}
