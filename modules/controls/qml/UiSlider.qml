import Blockstream.Theme
import QtQuick
import QtQuick.Controls.Basic as Basic

Basic.Slider {
    property Colors colors: Theme.colors
    property bool disabled: false
    id: self
    enabled: !self.disabled
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    padding: 10
    implicitWidth: horizontal ? 200 : 40
    implicitHeight: horizontal ? 40 : 200
    background: Rectangle {
        x: self.horizontal ? self.leftPadding : (self.width - width) / 2
        y: self.horizontal ? (self.height - height) / 2 : self.topPadding
        width: self.horizontal ? self.availableWidth : 4
        height: self.horizontal ? 4 : self.availableHeight
        radius: 2
        color: self.colors.surfaceSunken
        Rectangle {
            x: self.horizontal && self.mirrored ? parent.width - width : 0
            y: self.horizontal ? 0 : parent.height - height
            width: self.horizontal ? self.position * parent.width : parent.width
            height: self.horizontal ? parent.height : self.position * parent.height
            radius: 2
            color: self.enabled ? self.colors.actionPrimary : self.colors.actionDisabled
        }
    }
    handle: Rectangle {
        x: self.horizontal ? self.leftPadding + self.visualPosition * (self.availableWidth - width) : (self.width - width) / 2
        y: self.horizontal ? (self.height - height) / 2 : self.topPadding + self.visualPosition * (self.availableHeight - height)
        implicitWidth: 20
        implicitHeight: 20
        radius: 10
        color: !self.enabled ? self.colors.actionDisabled : self.pressed ? self.colors.actionPressed : self.hovered ? self.colors.actionHover : self.colors.actionPrimary
        border.color: self.colors.borderFocus
        border.width: self.visualFocus ? 2 : 0
    }
}
