import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtQml.Models

import "util.js" as UtilJS

ItemDelegate {
    required property Output output

    id: self
    hoverEnabled: true
    leftPadding: 20
    rightPadding: 20
    topPadding: 20
    bottomPadding: 20
    background: Item {
        Rectangle {
            anchors.fill: parent
            color: Qt.alpha('#00BCFF', (self.highlighted ? 0.2 : 0) + (self.hovered ? 0.1 : 0))
        }
        Rectangle {
            color: '#1F222A'
            width: parent.width
            height: 1
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
            asset: output.asset
        }
        ColumnLayout {
            Flow {
                Layout.fillWidth: true
                spacing: 10
                Repeater {
                    model: self.tags
                    delegate: Tag2 {
                        text: modelData.name
                        color: modelData.color ?? 'white'
                    }
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                font.pixelSize: 12
                font.weight: 400
                color: '#929292'
                text: self.output.data.txhash + ':' + self.output.data.pt_idx
                wrapMode: Label.Wrap
            }
        }
        ColumnLayout {
            Convert {
                id: convert
                account: self.output.account
                asset: self.output.asset
                input: ({ satoshi: String(self.output.data.satoshi) })
                unit: self.output.account.session.unit
            }
            Label {
                Layout.alignment: Qt.AlignRight
                font.family: 'Roboto Mono'
                font.features: { 'calt': 0, 'zero': 1 }
                font.pixelSize: 14
                font.weight: 600
                text: UtilJS.incognito(Settings.incognito, convert.output.label)
            }
            Label {
                Layout.alignment: Qt.AlignRight
                color: '#929292'
                font.family: 'Roboto Mono'
                font.features: { 'calt': 0, 'zero': 1 }
                font.pixelSize: 14
                font.weight: 600
                text: UtilJS.incognito(Settings.incognito, convert.fiat.label)
                visible: convert.fiat.available
            }
        }
    }
    readonly property var tags: {
        const output = self.output
        const tags = []
        if (output.expired) tags.push({ name: qsTrId('id_2fa_expired'), color: '#69302E' })
        if (output.locked) tags.push({ name: qsTrId('id_locked') })
        if (output.dust) tags.push({ name: qsTrId('id_dust') })
        if (output.account.network.liquid && !output.confidential) tags.push({ name: qsTrId('id_not_confidential') })
        tags.push({ name: localizedLabel(output.addressType) })
        if (output.unconfirmed) tags.push({ name: qsTrId('id_unconfirmed'), color: '#d2934a' })
        return tags
    }

    component Tag2: Tag {
        background: Rectangle {
            color: Qt.alpha('#FFF', 0.4)
            border.width: 1
            border.color: Qt.alpha('#FFF', 0.6)
            radius: height / 2
        }
        color: 'white'
        font.capitalization: Font.AllUppercase
    }
}
