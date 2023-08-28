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
    topPadding: 8
    bottomPadding: 8
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
        visible: self.isCurrent || self.hovered
        color: self.hovered ? constants.c600 : constants.c500
        radius: 4
    }
    contentItem: RowLayout {
        spacing: constants.s1
        Image {
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
