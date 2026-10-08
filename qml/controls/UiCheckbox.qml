import Blockstream.Theme
import QtQuick
import QtQuick.Controls.Basic as Basic
import QtQuick.Shapes

Basic.CheckBox {
    property bool disabled: false
    property Colors colors: Theme.colors
    property int wrapMode: Text.NoWrap
    property int elide: Text.ElideNone

    readonly property bool interactionHovered: self.enabled && !self.visualFocus && self.hovered
    readonly property bool marked: self.checkState !== Qt.Unchecked

    readonly property color boxColor: {
        if (!self.enabled) return self.colors.actionDisabled
        if (self.interactionHovered) return self.colors.actionHover
        return self.marked ? self.colors.actionPrimary : self.colors.borderBold
    }

    readonly property color markColor: self.enabled ? self.colors.actionOnPrimary : self.colors.textDisabled

    id: self
    implicitWidth: self.implicitContentWidth + self.leftPadding + self.rightPadding
    implicitHeight: Math.max(self.implicitIndicatorHeight, self.implicitContentHeight) + self.topPadding + self.bottomPadding
    padding: 0
    verticalPadding: 0
    spacing: 8
    enabled: !self.disabled
    focusPolicy: Qt.StrongFocus
    hoverEnabled: true
    Accessible.role: Accessible.CheckBox
    Accessible.name: self.text
    Accessible.checked: self.checked
    Accessible.checkStateMixed: self.checkState === Qt.PartiallyChecked

    indicator: Item {
        id: checkbox_indicator
        x: self.leftPadding
        y: self.topPadding + (self.availableHeight - checkbox_indicator.height) / 2
        implicitWidth: 20
        implicitHeight: 20
        // Outside the indicator bounds so focus does not change the control size.
        Rectangle {
            anchors.fill: checkbox_indicator
            anchors.margins: -2
            color: 'transparent'
            border.width: 2
            border.color: self.colors.borderFocus
            radius: 4
            visible: self.enabled && self.visualFocus
        }
        Rectangle {
            anchors.fill: checkbox_indicator
            color: self.marked ? self.boxColor : 'transparent'
            border.width: self.marked ? 0 : 2
            border.color: self.boxColor
            radius: 2
        }
        Shape {
            x: 5
            y: 6.6
            width: 10
            height: 7.2
            preferredRendererType: Shape.CurveRenderer
            visible: self.checkState === Qt.Checked
            ShapePath {
                strokeColor: self.markColor
                strokeWidth: 2
                fillColor: 'transparent'
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin
                startX: 0
                startY: 3.6
                PathLine { x: 3.6; y: 7.2 }
                PathLine { x: 10; y: 0 }
            }
        }
        Rectangle {
            anchors.centerIn: checkbox_indicator
            width: 10
            height: 2
            color: self.markColor
            radius: 1
            visible: self.checkState === Qt.PartiallyChecked
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
