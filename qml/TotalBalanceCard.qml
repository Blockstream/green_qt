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
        context: self.context
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
            font.pixelSize: 24
            font.weight: 600
            text: UtilJS.incognitoAmount(self.context, convert.unitLabel)
        }
        Label {
            font.pixelSize: 16
            font.weight: 400
            opacity: 0.6
            text: UtilJS.incognitoFiat(self.context, convert.fiatLabel)
        }
        VSpacer {
        }
    }
}
