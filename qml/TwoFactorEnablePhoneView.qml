import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

StackViewPage {
    signal next(string data)
    required property Session session
    required property string method
    readonly property Wallet wallet: session.context.wallet
    id: self
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    contentItem: ColumnLayout {
        spacing: 10
        Label {
            Layout.bottomMargin: 20
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            color: '#9C9C9C'
            font.pixelSize: 14
            font.weight: 400
            horizontalAlignment: Label.AlignHCenter
            text: qsTrId('id_insert_your_phone_number_to')
            wrapMode: Label.Wrap
        }
        PhoneField {
            Layout.maximumWidth: 300
            id: data_field
            focus: true
            selectByMouse: true
            onAccepted: change_action.trigger()
            onTextEdited: controller.clearErrors()
            Layout.fillWidth: true
            Layout.minimumWidth: 200
            Layout.alignment: Qt.AlignHCenter
        }
        FixedErrorBadge {
            Layout.alignment: Qt.AlignHCenter
            error: controller.errors.data
        }
        FixedErrorBadge {
            Layout.alignment: Qt.AlignHCenter
            pointer: false
            error: controller.errors.code
        }
        PrimaryButton {
            Layout.alignment: Qt.AlignHCenter
            Layout.minimumWidth: 150
            action: Action {
                id: change_action
                enabled: data_field.text !== ''
                onTriggered: self.next(data_field.phone)
            }
            text: qsTrId('id_next')
        }
        VSpacer {
        }
        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            Layout.topMargin: 20
            color: '#9C9C9C'
            font.pixelSize: 14
            font.weight: 400
            horizontalAlignment: Label.AlignHCenter
            text: `By continuing you agree to Blockstream's ${UtilJS.link('https://blockstream.com/green/terms/', 'Terms of Service')} and ${UtilJS.link('https://blockstream.com/green/privacy/', 'Privacy Policy')}`
            textFormat: Text.RichText
            wrapMode: Label.Wrap
            onLinkActivated: (link) => { Qt.openUrlExternally(link) }
        }
        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            color: '#9C9C9C'
            font.pixelSize: 14
            font.weight: 400
            horizontalAlignment: Label.AlignHCenter
            text: 'Message frequency varies according to the number of 2FA SMS requests you make.'
            wrapMode: Label.Wrap
        }
        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            Layout.topMargin: 20
            color: '#9C9C9C'
            font.pixelSize: 14
            font.weight: 400
            horizontalAlignment: Label.AlignHCenter
            text: `For help visit ${UtilJS.link('https://help.blockstream.com', 'help.blockstream.com')}`
            textFormat: Text.RichText
            wrapMode: Label.Wrap
            onLinkActivated: (link) => { Qt.openUrlExternally(link) }
        }
        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            color: '#9C9C9C'
            font.pixelSize: 14
            font.weight: 400
            horizontalAlignment: Label.AlignHCenter
            text: 'To unsubscribe turn off SMS 2FA from the app.'
            wrapMode: Label.Wrap
        }
        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            color: '#9C9C9C'
            font.pixelSize: 14
            font.weight: 400
            horizontalAlignment: Label.AlignHCenter
            text: 'Standard messages and data rates may apply.'
            wrapMode: Label.Wrap
        }
    }
}
