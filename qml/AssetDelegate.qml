import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ItemDelegate {
    property Account account
    property Asset asset
    property var satoshi
    readonly property var name: self.asset.data.name === 'btc' ? 'L-BTC' : self.asset.data?.name
    readonly property bool hasDetails: self.asset.hasData && self.asset.data.name !== 'btc'
    id: self
    hoverEnabled: self.hasDetails
    topPadding: 20
    leftPadding: 20
    rightPadding: 20
    bottomPadding: 20
    width: self.ListView.view.width
    background: Item {
        Rectangle {
            anchors.fill: parent
            visible: self.hovered
            color: '#00B45A'
            opacity: 0.08
        }
        Rectangle {
            color: '#FFFFFF'
            opacity: 0.1
            width: parent.width
            height: 1
            y: parent.height - 1
        }
    }
    contentItem: RowLayout {
        spacing: 20
        AssetIcon {
            Layout.alignment: Qt.AlignCenter
            asset: self.asset
        }
        ColumnLayout {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            spacing: 1
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                color: self.name ? '#FFF' : '#929292'
                font.pixelSize: 14
                font.weight: 600
                text: self.name ?? self.asset.id
                wrapMode: Label.Wrap
            }
            Label {
                color: '#929292'
                font.pixelSize: 12
                font.weight: 400
                text: self.asset.data.entity?.domain ?? ''
                visible: self.asset.data.entity?.domain ?? false
            }
        }
        ColumnLayout {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: false
            Convert {
                id: convert
                account: self.account
                asset: self.asset
                unit: 'sats'
                value: String(self.satoshi)
            }
            Label {
                Layout.alignment: Qt.AlignRight
                color: '#FFF'
                font.pixelSize: 14
                font.weight: 600
                text: convert.unitLabel
            }
            Label {
                Layout.alignment: Qt.AlignRight
                color: '#929292'
                font.pixelSize: 12
                font.weight: 400
                text: convert.fiatLabel
                visible: convert.result.fiat_currency ?? false
            }
        }
    }
}
