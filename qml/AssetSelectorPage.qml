import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    signal assetClicked(Asset asset)

    required property Context context
    required property var networks
    required property var assets
    objectName: "AssetSelectorPage"
    id: self
    padding: 0
    background: null
    contentItem: VFlickable {
        alignment: Qt.AlignTop
        spacing: 8
        Repeater {
            model: self.assets
            delegate: AssetButton {
                required property var modelData
                Layout.fillWidth: true
                id: delegate
                asset: delegate.modelData.asset
                satoshi: delegate.modelData.satoshi
            }
        }
        VSpacer {
        }
    }

    component AssetButton: AbstractButton {
        required property Asset asset
        required property var satoshi
        Convert {
            id: convert
            context: self.context
            asset: button.asset
            input: ({ satoshi: button.satoshi })
            unit: self.context.primarySession.unit
        }
        onClicked: self.assetClicked(button.asset)
        id: button
        leftPadding: 24
        rightPadding: 24
        topPadding: 12
        bottomPadding: 12
        background: Rectangle {
            border.color: '#262626'
            border.width: 1
            color: Qt.lighter('#181818', button.enabled && button.hovered ? 1.2 : 1)
            radius: 8
        }
        contentItem: RowLayout {
            spacing: 12
            AssetIcon {
                asset: button.asset
                size: 27
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                color: button.asset.name ? '#FFF' : '#929292'
                font.pixelSize: 16
                font.weight: 600
                text: button.asset.name || button.asset.id
                elide: Label.ElideRight
            }
            ColumnLayout {
                spacing: 0
                Label {
                    Layout.alignment: Qt.AlignRight
                    color: '#00BCFF'
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
            RightArrowIndicator {
                active: button.hovered
            }
        }
    }
}
