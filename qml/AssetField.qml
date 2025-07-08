import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

AbstractButton {
    required property Asset asset
    property bool anyLiquid: false
    property bool anyAMP: false
    property bool editable: true

    id: self
    leftPadding: 20
    rightPadding: 20
    topPadding: 10
    bottomPadding: 10
    activeFocusOnTab: self.editable
    background: Rectangle {
        color: Qt.lighter('#222226', self.enabled && self.editable && self.hovered ? 1.2 : 1)
        radius: 5
        Rectangle {
            border.width: 2
            border.color: '#00BCFF'
            color: 'transparent'
            radius: 9
            anchors.fill: parent
            anchors.margins: -4
            opacity: self.visualFocus ? 1 : 0
        }
    }
    contentItem: RowLayout {
        spacing: 10
        Image {
            Layout.maximumHeight: 32
            Layout.maximumWidth: 32
            source: {
                if (self.anyLiquid) return 'qrc:/svg2/liquid_icon.svg'
                if (self.anyAMP) return 'qrc:/svg2/amp_icon.svg'
                return UtilJS.iconFor(self.asset)
            }
        }
        Label {
            Layout.fillWidth: true
            font.pixelSize: 14
            font.weight: 500
            text: {
                if (self.anyLiquid) return 'Receive any Liquid Asset'
                if (self.anyAMP) return 'Receive any AMP Asset'
                return self.asset?.name ?? ''
            }
            wrapMode: Label.WrapAtWordBoundaryOrAnywhere
        }
        Image {
            visible: self.editable
            source: 'qrc:/svg2/edit.svg'
        }
    }
}
