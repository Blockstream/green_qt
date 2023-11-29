import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

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
            spacing: 10
            Label {
                font.capitalization: Font.AllUppercase
                font.pixelSize: 12
                font.weight: 400
                opacity: 0.6
                text: qsTrId('id_total_balance')
            }
            Image {
                opacity: 0.6
                source: 'qrc:/svg2/eye.svg'
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
            text: formatAmount(self.account, self.balance)
        }
        Label {
            font.capitalization: Font.AllUppercase
            font.pixelSize: 16
            font.weight: 400
            opacity: 0.6
            text: formatFiat(self.balance)
        }
        VSpacer {
        }
    }
}
