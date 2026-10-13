import Blockstream.Theme
import QtQuick
import QtQuick.Controls.Basic as Basic

Basic.Switch {
    property bool disabled: false
    property Colors colors: Theme.colors
    property int wrapMode: Text.NoWrap
    property int elide: Text.ElideNone

    readonly property bool interactionHovered: self.enabled && !self.visualFocus && self.hovered
    readonly property bool focusRingVisible: self.enabled && self.visualFocus

    readonly property color trackColor: {
        if (!self.enabled) return self.colors.actionDisabled
        if (self.checked) return self.interactionHovered ? self.colors.actionHover : self.colors.actionPrimary
        return self.interactionHovered ? self.colors.surfaceHover : self.colors.surfaceRaised
    }

    readonly property color knobColor: self.enabled ? self.colors.iconBase : self.colors.textDisabled

    id: self
    implicitWidth: self.implicitContentWidth + self.leftPadding + self.rightPadding
    implicitHeight: Math.max(self.implicitIndicatorHeight, self.implicitContentHeight) + self.topPadding + self.bottomPadding
    padding: 0
    rightPadding: self.indicator.width + (self.text.length > 0 ? self.spacing : 0)
    spacing: 8
    enabled: !self.disabled
    focusPolicy: Qt.StrongFocus
    hoverEnabled: true
    Accessible.role: Accessible.Switch
    Accessible.name: self.text
    Accessible.checked: self.checked

    indicator: Item {
        id: toggle_indicator
        readonly property int trackMargin: self.focusRingVisible ? 4 : 0
        readonly property int knobInset: 3

        x: self.width - toggle_indicator.width
        y: self.topPadding + (self.availableHeight - toggle_indicator.height) / 2
        implicitWidth: 48
        implicitHeight: 28
        // The focus ring stays inside the control, so the track and knob shrink instead of the control growing.
        Rectangle {
            anchors.fill: toggle_indicator
            color: 'transparent'
            border.width: 2
            border.color: self.colors.borderFocus
            radius: height / 2
            visible: self.focusRingVisible
        }
        Rectangle {
            id: track
            anchors.fill: toggle_indicator
            anchors.margins: toggle_indicator.trackMargin
            color: self.trackColor
            radius: height / 2
        }
        Rectangle {
            id: knob
            x: track.x + toggle_indicator.knobInset + self.visualPosition * (track.width - width - 2 * toggle_indicator.knobInset)
            y: track.y + toggle_indicator.knobInset
            width: track.height - 2 * toggle_indicator.knobInset
            height: width
            color: self.knobColor
            radius: width / 2
            Behavior on x {
                enabled: !self.down
                SmoothedAnimation { velocity: 200 }
            }
        }
    }

    contentItem: UiLabel {
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
