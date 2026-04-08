import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

Pane {
    signal assetClicked(Asset asset)

    required property Context context
    readonly property var assets: UtilJS.assets(self.context)
    id: self
    padding: 0
    background: null
    contentItem: ColumnLayout {
        spacing: 8
        ColumnLayout {
            spacing: 4
            visible: self.assets.length === 0
            Label {
                Layout.fillWidth: true
                color: '#929292'
                font.pixelSize: 14
                text: 'You don\'t have any assets yet.'
            }
            RowLayout {
                spacing: 0
                LinkButton {
                    text: 'Fund your wallet'
                }
                Label {
                    color: '#929292'
                    font.pixelSize: 14
                    font.weight: 400
                    text: ' now.'
                }
            }
        }
        Repeater {
            model: self.assets
            delegate: AssetButton {
                required property var modelData
                Layout.fillWidth: true
                Layout.maximumHeight: 60
                Layout.minimumHeight: 60
                id: delegate
                asset: delegate.modelData.asset
                satoshi: delegate.modelData.satoshi
                onClicked: self.assetClicked(delegate.asset)
            }
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
        id: button
        leftPadding: 24
        rightPadding: 24
        topPadding: 12
        bottomPadding: 12
        focusPolicy: Qt.ClickFocus
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
