import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    signal start()

    id: self
    padding: 60
    leftItem: BackButton {
        text: qsTrId('id_wallets')
        onClicked: self.closeClicked()
    }
    Image {
        Layout.alignment: Qt.AlignCenter
        source: 'qrc:/svg2/blockstream-app.svg'
    }
    Label {
        Layout.alignment: Qt.AlignCenter
        Layout.maximumWidth: 300
        Layout.topMargin: 50
        color: '#FFF'
        font.pixelSize: 30
        font.weight: 656
        horizontalAlignment: Label.AlignHCenter
        text: qsTrId('id_simple__secure_selfcustody')
        wrapMode: Label.WordWrap
    }
    Label {
        Layout.alignment: Qt.AlignCenter
        Layout.fillWidth: true
        Layout.maximumWidth: 300
        Layout.topMargin: 10
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
        Layout.topMargin: 10
        enabled: tos_check_box.checked
        text: 'Get Started'
        onClicked: self.start()
    }
    RowLayout {
        Layout.alignment: Qt.AlignCenter
        Layout.fillWidth: false
        Layout.fillHeight: false
        Layout.topMargin: 20
        spacing: 0
        CheckBox {
            id: tos_check_box
            Layout.alignment: Qt.AlignCenter
            bottomInset: 0
            topInset: 0
            leftInset: 0
            rightInset: 0
            checked: Settings.acceptedTermsOfService
        }
        LinkLabel {
            Layout.alignment: Qt.AlignCenter
            font.pixelSize: 14
            font.weight: 600
            text: {
                const terms = new RegExp('(' + qsTrId('id_terms_of_service') + ')', 'gi')
                const privacy = new RegExp('(' + qsTrId('id_privacy_policy') + ')', 'gi')
                return qsTrId('id_i_agree_to_the_terms_of_service')
                    .replace(terms, UtilJS.link('https://blockstream.com/green/terms/', '$1'))
                    .replace(privacy, UtilJS.link('https://blockstream.com/green/privacy/', '$1'))
            }
        }
    }
}
