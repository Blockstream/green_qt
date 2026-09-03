import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

ItemDelegate {
    required property Output output
    required property string unit

    signal detailsRequested()

    id: self
    hoverEnabled: true
    horizontalPadding: 16
    verticalPadding: 16

    background: Rectangle {
        color: self.hovered ? '#232323' : '#181818'
        border.color: '#232323'
        border.width: 1
        radius: 4
    }

    contentItem: RowLayout {
        spacing: 12

        Item {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20

            Rectangle {
                anchors.fill: parent
                border.color: self.checked ? '#FFFFFF' : '#404040'
                border.width: 2
                color: 'transparent'
                radius: 2
            }

            Image {
                anchors.centerIn: parent
                source: 'qrc:/svg2/check-coin.svg'
                visible: self.checked
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Label {
                Layout.fillWidth: true
                color: '#FFFFFF'
                font.pixelSize: 14
                font.weight: 600
                elide: Label.ElideRight
                text: UtilJS.shortenOutpoint(self.output.data.txhash, self.output.data.pt_idx)
            }

            Label {
                color: '#A0A0A0'
                font.pixelSize: 12
                font.weight: 400
                text: self.output.unconfirmed ? qsTrId('id_unconfirmed') : 'Confirmed'
            }
        }

        Convert {
            id: convert
            account: self.output.account
            asset: self.output.asset
            input: ({ satoshi: String(self.output.data.satoshi ?? 0) })
            unit: self.unit
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            Label {
                Layout.alignment: Qt.AlignRight
                color: '#FFFFFF'
                font.pixelSize: 14
                font.weight: 600
                text: UtilJS.incognito(Settings.incognito, convert.output.label)
            }

            Label {
                Layout.alignment: Qt.AlignRight
                color: '#A0A0A0'
                font.pixelSize: 12
                font.weight: 400
                text: UtilJS.incognito(Settings.incognito, convert.fiat.label)
                visible: convert.fiat.available
            }
        }

        AbstractButton {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            padding: 0
            background: null
            contentItem: Item {
                Image {
                    anchors.fill: parent
                    source: 'qrc:/svg2/info.svg'
                }
            }
            onClicked: self.detailsRequested()
        }
    }
}
