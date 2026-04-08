import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

WalletHeaderCard {
    readonly property string currency: UtilJS.currency(self.context)
    readonly property var total: {
        let loading = false
        let value = 0

        for (let index = 0; index < assets.count; index++) {
            const fiat = assets.objectAt(index).fiat
            if (!fiat.available) continue

            // Currency is not updated means conversion is still loading
            if (fiat.currency !== self.currency) {
                loading = true
            }

            value += fiat.value
        }

        return { loading, value }
    }

    id: self

    headerItem: RowLayout {
        Label {
            Layout.alignment: Qt.AlignCenter
            color: '#A0A0A0'
            font.pixelSize: 12
            font.weight: 400
            text: qsTrId('id_total_balance')
        }
        AbstractButton {
            contentItem: Image {
                Layout.alignment: Qt.AlignCenter
                sourceSize.width: 20
                sourceSize.height: 20
                source: Settings.incognito ? 'qrc:/svg2/eye_closed.svg' : 'qrc:/svg2/eye.svg'
            }
            onClicked: {
                Settings.toggleIncognito()
                if (Settings.incognito) {
                    Analytics.recordEvent('hide_amount', AnalyticsJS.segmentationSession(Settings, self.context))
                }
            }
        }
        HSpacer {
        }
    }

    contentItem: ColumnLayout {
        Label {
            id: total_balance_label
            topPadding: 4
            font.pixelSize: 22
            font.weight: 600
            text: UtilJS.incognito(Settings.incognito, UtilJS.formatAmount(self.total.value, self.currency))
            visible: !self.total.loading
        }
        BusyIndicator {
            Layout.preferredHeight: total_balance_label.implicitHeight
            Layout.preferredWidth: total_balance_label.implicitHeight
            running: self.total.loading
            visible: self.total.loading
        }
        VSpacer {
        }
    }

    Instantiator {
        id: assets
        model: UtilJS.assets(self.context)
        delegate: Convert {
            required property var modelData
            id: delegate
            context: self.context
            asset: delegate.modelData.asset
            input: ({ satoshi: String(delegate.modelData.satoshi) })
        }
    }
}
