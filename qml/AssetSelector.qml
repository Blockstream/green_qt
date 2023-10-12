import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    required property Asset asset
    signal selected(asset: Asset)

    id: self
    title: qsTrId('id_select_asset')
    contentItem: ListView {
        currentIndex: {
            if (self.asset) {
                for (let i = 0; i < count; i++) {
                    if (itemAtIndex(i).asset === self.asset) {
                        return i
                    }
                }
            }
            return -1
        }
        focus: true
        spacing: 10
        model: AssetsModel {
            minWeight: 1
        }
        delegate: ItemDelegate {
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
                color: '#222226'
                radius: 5
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -4
                    border.width: 2
                    border.color: '#00B45A'
                    color: 'transparent'
                    radius: 9
                    visible: {
                        if (delegate.activeFocus) {
                            switch (delegate.focusReason) {
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
                Rectangle {
                    anchors.fill: parent
                    border.width: 2
                    border.color: '#00B45A'
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
                    font.family: 'SF Compact Display'
                    font.pixelSize: 14
                    font.weight: 500
                    text: delegate.asset.name
                    wrapMode: Label.WrapAtWordBoundaryOrAnywhere
                }
            }
            onClicked: {
                ListView.view.currentIndex = delegate.index
                self.selected(delegate.asset)
            }
        }
    }
}
