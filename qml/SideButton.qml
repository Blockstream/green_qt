import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Button {
    id: self
    property int count: 0
    required property bool isCurrent
    property bool busy: false
    property bool ready: false
    topPadding: 16
    bottomPadding: 16
    leftPadding: 16
    rightPadding: 16
    topInset: 0
    leftInset: 0
    rightInset: 0
    bottomInset: 0

    Layout.fillWidth: true
    icon.width: 24
    icon.height: 24
    background: Rectangle {
        visible: self.enabled && (self.isCurrent || self.hovered)
        color: Qt.rgba(1, 1, 1, self.hovered ? 0.05 : 0)
        Rectangle {
            visible: self.isCurrent
            width: 1
            color: 'white'
            x: parent.width - 2
            height: parent.height
        }
    }
    contentItem: RowLayout {
        spacing: 0
        Image {
            Layout.alignment: Qt.AlignCenter
            opacity: self.enabled ? 1 : 0.4
            source: self.icon.source
            sourceSize.width: self.icon.width
            sourceSize.height: self.icon.height
        }
    }

    LeftArrowToolTip {
        parent: self
        text: self.text
        font: self.font
        visible: self.enabled && self.hovered
    }
}
