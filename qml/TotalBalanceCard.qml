import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

WalletHeaderCard {
    Convert {
        id: convert
        unit: 'sats'
        value: {
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
        account: {
            const context = self.context
            if (context) {
                const session = context.sessions[0]
                for (let i = 0; i < context.accounts.length; i++) {
                    const account = context.accounts[i]
                    if (account.session === session) {
                        return account
                    }
                }
            }
            return null
        }
    }

    id: self
    headerItem: RowLayout {
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
            source: self.context.wallet.incognito ? 'qrc:/svg2/eye_closed.svg' : 'qrc:/svg2/eye.svg'
            TapHandler {
                onTapped: self.context.wallet.toggleIncognito()
            }
        }
        HSpacer {
            Layout.minimumHeight: 28
        }
    }
    contentItem: ColumnLayout {
        spacing: 10
        Label {
            font.capitalization: Font.AllUppercase
            font.pixelSize: 24
            font.weight: 600
            text: UtilJS.incognitoAmount(convert.account, convert.unitLabel)
        }
        Label {
            font.capitalization: Font.AllUppercase
            font.pixelSize: 16
            font.weight: 400
            opacity: 0.6
            text: UtilJS.incognitoFiat(convert.account, convert.fiatLabel)
        }
        VSpacer {
        }
    }
}
