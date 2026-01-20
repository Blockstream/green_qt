import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    signal anyLiquidClicked()
    signal anyAMPClicked()
    signal assetClicked(asset: Asset)
    required property Context context
    required property Asset asset

    objectName: "AssetSelector"
    id: self
    title: qsTrId('id_select_asset')
    contentItem: ColumnLayout {
        spacing: 5
        SearchField {
            Layout.fillWidth: true
            id: search_field
        }
        FieldTitle {
            text: {
                if (search_field.text.trim().length === 0) return 'Other Assets'
                if (list_view.count === 0) return 'No search results'
                return 'Search results'
            }
        }
        TListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            footer: ColumnLayout {
                width: list_view.width
                spacing: 5
                OptionButton {
                    Layout.topMargin: 5
                    icon.source: 'qrc:/svg2/liquid_icon.svg'
                    text: 'Receive any Liquid Asset'
                    onClicked: self.anyLiquidClicked()
                }
                OptionButton {
                    icon.source: 'qrc:/svg2/amp_icon.svg'
                    text: 'Receive any AMP Asset'
                    onClicked: self.anyAMPClicked()
                }
            }
            id: list_view
            currentIndex: {
                if (self.asset) {
                    for (let i = 0; i < list_view.count; i++) {
                        if (list_view.itemAtIndex(i)?.asset === self.asset) {
                            return i
                        }
                    }
                }
                return -1
            }
            focus: true
            spacing: 5
            model: AssetsModel {
                context: self.context
                filter: search_field.text.trim()
                minWeight: search_field.text.trim().length === 0 ? 1 : 0
            }
            delegate: AssetDelegate {
            }
        }
    }

    component OptionButton: AbstractButton {
        Layout.fillWidth: true
        id: button
        leftPadding: 20
        rightPadding: 20
        topPadding: 10
        bottomPadding: 10
        background: Rectangle {
            color: Qt.lighter('#181818', button.hovered ? 1.2 : 1)
            radius: 5
            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                border.width: 2
                border.color: '#00BCFF'
                color: 'transparent'
                radius: 9
                visible: {
                    if (button.activeFocus) {
                        switch (button.focusReason) {
                        case Qt.TabFocusReason:
                        case Qt.BacktabFocusReason:
                        case Qt.ShortcutFocusReason:
                            return true
                        }
                    }
                    return false
                }
                z: -1
            }
        }
        contentItem: RowLayout {
            spacing: 10
            Image {
                property real size: 32
                source: button.icon.source
                Layout.preferredHeight: size
                Layout.preferredWidth: size
                height: size
                width: size
                fillMode: Image.PreserveAspectFit
                mipmap: true
            }
            Label {
                Layout.fillWidth: true
                font.pixelSize: 14
                font.weight: 500
                text: button.text
                wrapMode: Label.WrapAtWordBoundaryOrAnywhere
            }
        }
    }

    component AssetDelegate: ItemDelegate {
        required property Asset asset
        required property int index
        id: delegate
        activeFocusOnTab: true
        leftPadding: 20
        rightPadding: 20
        topPadding: 10
        bottomPadding: 10
        highlighted: ListView.isCurrentItem
        background: Rectangle {
            color: Qt.lighter('#181818', delegate.hovered ? 1.2 : 1)
            radius: 5
            Rectangle {
                anchors.fill: parent
                border.width: 2
                border.color: '#00BCFF'
                color: 'transparent'
                radius: 5
                visible: delegate.highlighted
            }
        }
        width: ListView.view.width
        contentItem: RowLayout {
            spacing: 10
            Image {
                property real size: 32
                source: UtilJS.iconFor(delegate.asset)
                Layout.preferredHeight: size
                Layout.preferredWidth: size
                height: size
                width: size
                fillMode: Image.PreserveAspectFit
                mipmap: true
            }
            Label {
                Layout.fillWidth: true
                font.pixelSize: 14
                font.weight: 500
                text: delegate.asset.name
                wrapMode: Label.WrapAtWordBoundaryOrAnywhere
            }
        }
        onClicked: {
            ListView.view.currentIndex = delegate.index
            self.assetClicked(delegate.asset)
        }
    }
}
