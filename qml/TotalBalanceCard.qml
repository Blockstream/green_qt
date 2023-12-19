import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

WalletHeaderCard {
    // TODO: remove this property, only required for formatAmount which should be refactored
    required property Account account

    readonly property var balance: {
        const context = self.context
        let r = 0
        if (context) {
            for (let i = 0; i < context.accounts.length; i++) {
                const account = context.accounts[i]
                r += account.balance
            }
        }
        return r
    }
    id: self
    contentItem: ColumnLayout {
        spacing: 10
        RowLayout {
            Layout.minimumHeight: 28
            spacing: 10
            Label {
                Layout.alignment: Qt.AlignCenter
                font.capitalization: Font.AllUppercase
                font.pixelSize: 12
                font.weight: 400
                opacity: 0.6
                text: qsTrId('id_total_balance')
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                opacity: 0.6
                source: self.account.context.wallet.incognito ? 'qrc:/svg2/eye_closed.svg' : 'qrc:/svg2/eye.svg'
                TapHandler {
                    onTapped: self.account.context.wallet.toggleIncognito()
                }
            }
            HSpacer {
            }
        }
        VSpacer {
        }
        Label {
            font.capitalization: Font.AllUppercase
            font.pixelSize: 24
            font.weight: 600
            text: UtilJS.incognitoAmount(self.account, formatAmount(self.account, self.balance))
            layer.enabled: true
        }
        Label {
            font.capitalization: Font.AllUppercase
            font.pixelSize: 16
            font.weight: 400
            opacity: 0.6
            text: UtilJS.incognitoFiat(self.account, formatFiat(self.balance))
        }
        VSpacer {
        }
    }
}
