import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ItemDelegate {
    signal assetClicked(Asset asset)
    property Account account
    property Asset asset
    property var satoshi
    readonly property bool hasDetails: self.asset.hasData
    onClicked: if (self.hasDetails) self.assetClicked(self.asset)
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
            color: '#00BCFF'
            opacity: 0.08
        }
        Rectangle {
            color: '#1F222A'
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
                color: self.asset.name ? '#FFF' : '#929292'
                font.pixelSize: 14
                font.weight: 600
                text: self.asset.name || self.asset.id
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
                input: ({ satoshi: String(self.satoshi) })
                unit: self.account.session.unit
            }
            Label {
                Layout.alignment: Qt.AlignRight
                color: '#FFF'
                font.pixelSize: 14
                font.weight: 600
                text: convert.output.label
            }
            Label {
                Layout.alignment: Qt.AlignRight
                color: '#929292'
                font.pixelSize: 12
                font.weight: 400
                text: convert.fiat.label
                visible: convert.fiat.available
            }
        }
    }
}
