import Blockstream.Theme
import QtQuick
import QtQuick.Controls.Basic as Basic

Basic.RadioButton {
    property bool disabled: false
    property Colors colors: Theme.colors
    property int wrapMode: Text.NoWrap
    property int elide: Text.ElideNone

    readonly property bool interactionHovered: self.enabled && !self.visualFocus && self.hovered

    readonly property color ringColor: {
        if (!self.enabled) return self.colors.actionDisabled
        if (self.interactionHovered) return self.colors.actionHover
        return self.checked ? self.colors.actionPrimary : self.colors.borderBold
    }

    readonly property color dotColor: {
        if (!self.enabled) return self.colors.textDisabled
        return self.interactionHovered ? self.colors.actionHover : self.colors.actionPrimary
    }

    id: self
    implicitWidth: self.implicitContentWidth + self.leftPadding + self.rightPadding
    implicitHeight: Math.max(self.implicitIndicatorHeight, self.implicitContentHeight) + self.topPadding + self.bottomPadding
    padding: 0
    verticalPadding: 0
    spacing: 8
    enabled: !self.disabled
    focusPolicy: Qt.StrongFocus
    hoverEnabled: true
    Accessible.role: Accessible.RadioButton
    Accessible.name: self.text
    Accessible.checked: self.checked

    indicator: Item {
        id: radio_indicator
        x: self.leftPadding
        y: self.topPadding + (self.availableHeight - radio_indicator.height) / 2
        implicitWidth: 20
        implicitHeight: 20
        // Outside the indicator bounds so focus does not change the control size.
        Rectangle {
            anchors.fill: radio_indicator
            anchors.margins: -2
            color: 'transparent'
            border.width: 2
            border.color: self.colors.borderFocus
            radius: width / 2
            visible: self.enabled && self.visualFocus
        }
        Rectangle {
            anchors.fill: radio_indicator
            color: 'transparent'
            border.width: 2
            border.color: self.ringColor
            radius: width / 2
        }
        Rectangle {
            anchors.centerIn: radio_indicator
            width: 10
            height: 10
            color: self.dotColor
            radius: width / 2
            visible: self.checked
        }
    }

    contentItem: UiLabel {
        leftPadding: self.indicator.width + (self.text.length > 0 ? self.spacing : 0)
        width: self.availableWidth
        text: self.text
        typography: Theme.typography.bodyM
        color: self.enabled ? self.colors.textPrimary : self.colors.textDisabled
        verticalAlignment: Text.AlignVCenter
        wrapMode: self.wrapMode
        elide: self.elide
        Accessible.ignored: true
    }
    background: null
}
