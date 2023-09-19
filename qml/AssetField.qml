import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

AbstractButton {
    required property Asset asset
    property bool editable: true

    id: self
    leftPadding: 20
    rightPadding: 20
    topPadding: 10
    bottomPadding: 10
    activeFocusOnTab: self.editable
    background: Rectangle {
        color: '#222226'
        radius: 5
        Rectangle {
            border.width: 2
            border.color: '#00B45A'
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
            source: UtilJS.iconFor(self.asset)
        }
        Label {
            Layout.fillWidth: true
            font.family: 'SF Compact Display'
            font.pixelSize: 14
            font.weight: 500
            text: self.asset?.name ?? ''
            wrapMode: Label.WrapAtWordBoundaryOrAnywhere
        }
        Image {
            visible: self.editable
            source: 'qrc:/svg2/edit.svg'
        }
    }
}
