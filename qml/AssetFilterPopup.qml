import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

FilterPopup {
    required property Context context
    required property ContextModel model
    property var filterAssets: []
    property var assets: []
    Component.onCompleted: {
        self.filterAssets = [...self.model.filterAssets]
        self.assets = UtilJS.assets(self.context)
            .filter(entry => !self.filterAssets.includes(entry.asset))
    }
    id: self
    Repeater {
        model: self.filterAssets
        delegate: Delegate {
            required property var modelData
            Layout.fillWidth: true
            Layout.maximumWidth: 400
            id: delegate2
            asset: delegate2.modelData
        }
    }
    FilterPopup.Separator {
        visible: self.filterAssets.length > 0 && self.assets.length > 0
    }
    Repeater {
        model: self.assets
        delegate: Delegate {
            required property var modelData
            Layout.fillWidth: true
            Layout.maximumWidth: 400
            id: delegate
            asset: delegate.modelData.asset
        }
    }
    component Delegate: AbstractButton {
        required property Asset asset
        checkable: true
        checked: self.model.filterAssets.includes(button.asset)
        onClicked: {
            self.model.updateFilterAssets(button.asset, !self.model.filterAssets.includes(button.asset))
        }
        id: button
        leftPadding: 12
        rightPadding: 12
        topPadding: 4
        bottomPadding: 4
        background: Rectangle {
            color: '#FFF'
            radius: 8
            opacity: 0.2
            visible: button.hovered
        }
        contentItem: RowLayout {
            spacing: 12
            AssetIcon {
                asset: button.asset
                size: 24
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                color: button.asset.name ? '#FFF' : '#929292'
                font.pixelSize: 14
                font.weight: 400
                text: button.asset.name || button.asset.id
                elide: Label.ElideMiddle
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/check.svg'
                opacity: button.checked ? 1 : 0
            }
        }
    }
}
