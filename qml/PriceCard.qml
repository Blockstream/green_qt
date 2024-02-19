import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

WalletHeaderCard {
    Convert {
        id: convert
        context: self.context
        input: ({ btc: '1' })
        unit: self.context.primarySession.unit
    }
    id: self
    headerItem: RowLayout {
        Image {
            Layout.alignment: Qt.AlignCenter
            opacity: 0.6
            source: 'qrc:/svg2/bolt.svg'
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            font.capitalization: Font.AllUppercase
            font.pixelSize: 12
            font.weight: 400
            opacity: 0.6
            text: qsTrId('id_price_feed')
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
            text: convert.fiat.label
        }
        Label {
            font.pixelSize: 16
            font.weight: 400
            opacity: 0.6
            text: convert.output.label
        }
        VSpacer {
        }
    }
}
