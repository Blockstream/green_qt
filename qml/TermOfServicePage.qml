import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    signal start()
    signal startDevice()

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
        Layout.maximumWidth: 450
        Layout.topMargin: 48
        color: '#FFF'
        font.pixelSize: 26
        font.weight: 656
        horizontalAlignment: Label.AlignHCenter
        text: qsTrId('id_simple__secure_selfcustody')
        wrapMode: Label.WordWrap
    }
    Label {
        Layout.alignment: Qt.AlignCenter
        Layout.fillWidth: true
        Layout.maximumWidth: 400
        Layout.topMargin: 10
        font.pixelSize: 14
        font.weight: 400
        horizontalAlignment: Label.AlignHCenter
        text: qsTrId('id_everything_you_need_to_take')
        wrapMode: Label.WordWrap
    }
    PrimaryButton {
        Layout.alignment: Qt.AlignCenter
        Layout.fillWidth: true
        Layout.maximumWidth: 325
        Layout.topMargin: 96
        font.weight: 500
        text: qsTrId('id_get_started')
        onClicked: {
            Settings.acceptTermsOfService()
            self.start()
        }
    }
    RegularButton {
        Layout.alignment: Qt.AlignCenter
        Layout.fillWidth: true
        Layout.maximumWidth: 325
        Layout.topMargin: 18
        cyan: true
        font.weight: 500
        text: qsTrId('id_connect_jade')
        onClicked: {
            Settings.acceptTermsOfService()
            self.startDevice()
        }
    }
    LinkLabel {
        Layout.alignment: Qt.AlignCenter
        Layout.maximumWidth: 325
        Layout.topMargin: 18
        font.pixelSize: 14
        horizontalAlignment: Label.AlignHCenter
        wrapMode: Label.WordWrap
        text: {
            const terms = new RegExp('(Terms & Conditions)', 'gi')
            const privacy = new RegExp('(Privacy Policy)', 'gi')
            return 'By using the Blockstream app, you agree to the Terms & Conditions and Privacy Policy.'
                .replace(terms, UtilJS.link('https://blockstream.com/app/terms/', '$1'))
                .replace(privacy, UtilJS.link('https://blockstream.com/app/privacy/', '$1'))
        }
    }
}
