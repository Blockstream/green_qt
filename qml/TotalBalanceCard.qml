import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

WalletHeaderCard {
    Convert {
        id: convert
        context: self.context
        input: ({ satoshi: String(UtilJS.accounts(self.context).reduce((balance, account) => balance + account.balance, 0)) })
        unit: UtilJS.unit(self.context)
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
                onTapped: {
                    Settings.toggleIncognito()
                    if (Settings.incognito) {
                        Analytics.recordEvent('hide_amount', AnalyticsJS.segmentationSession(Settings, self.context))
                    }
                }
            }
        }
        HSpacer {
            Layout.minimumHeight: 28
        }
    }
    contentItem: ColumnLayout {
        spacing: 10
        Label {
            font.pixelSize: 20
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
