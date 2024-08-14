import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS

StackViewPage {
    signal next(string data)
    signal closed()
    required property Session session
    id: self
    rightItem: CloseButton {
        onClicked: self.closed()
    }
    contentItem: ColumnLayout {
        spacing: 10
        Spacer {
        }
        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            horizontalAlignment: Label.AlignHCenter
            text: qsTrId('id_scan_the_qr_code_with_an')
            wrapMode: Text.WordWrap
        }
        QRCode {
            Layout.alignment: Qt.AlignCenter
            implicitHeight: 200
            implicitWidth: 200
            text: {
                const wallet = self.session.context.wallet
                const name = wallet.name
                const label = name + ' @ Green ' + session.network.displayName
                const secret = self.session.config.gauth.data.split('=')[1]
                return 'otpauth://totp/' + escape(label) + '?secret=' + secret
            }
        }
        SectionLabel {
            Layout.topMargin: 10
            Layout.alignment: Qt.AlignHCenter
            text: qsTrId('id_authenticator_secret_key')
        }
        CopyAddressButton {
            Layout.alignment: Qt.AlignHCenter
            text: self.session.config.gauth.data.split('=')[1] || ''
        }
        PrimaryButton {
            Layout.alignment: Qt.AlignHCenter
            Layout.minimumWidth: 150
            text: qsTrId('id_next')
            onClicked: self.next(self.session.config.gauth.data)
        }
        VSpacer {
        }
    }
}
