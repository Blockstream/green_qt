import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

WalletHeaderCard {
    Convert {
        id: convert
        context: self.context
        input: {
            const context = self.context
            let balance = 0
            if (context) {
                for (let i = 0; i < context.accounts.length; i++) {
                    const account = context.accounts[i]
                    balance += account.balance
                }
            }
            return { satoshi: String(balance) }
        }
        unit: self.context.primarySession.unit
    }

    id: self
    headerItem: RowLayout {
        Label {
            Layout.alignment: Qt.AlignCenter
            color: '#FFF'
            font.capitalization: Font.AllUppercase
            font.pixelSize: 12
            font.weight: 400
            opacity: 0.6
            text: qsTrId('id_total_balance')
        }
        Image {
            Layout.alignment: Qt.AlignCenter
            source: Settings.incognito ? 'qrc:/svg2/eye_closed.svg' : 'qrc:/svg2/eye.svg'
            TapHandler {
                onTapped: Settings.toggleIncognito()
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
            text: UtilJS.incognito(Settings.incognito, convert.output.label)
        }
        Label {
            font.pixelSize: 16
            font.weight: 400
            opacity: 0.6
            text: UtilJS.incognito(Settings.incognito, convert.fiat.label)
        }
        VSpacer {
        }
    }
}
