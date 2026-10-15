import Blockstream.Theme
import QtQuick
import QtQuick.Controls.Basic as Basic

Basic.TabButton {
    property bool disabled: false
    property Colors colors: Theme.colors
    property int wrapMode: Text.NoWrap
    property int elide: Text.ElideNone

    readonly property bool interactionHovered: self.enabled && !self.visualFocus && self.hovered

    readonly property color labelColor: {
        if (!self.enabled) return self.colors.textDisabled
        if (self.checked) return self.colors.textPrimary
        return self.interactionHovered ? self.colors.textPrimary : self.colors.textSubtle
    }

    id: self
    width: self.implicitWidth
    implicitWidth: self.implicitContentWidth + self.leftPadding + self.rightPadding
    implicitHeight: Math.max(60, self.implicitContentHeight + self.topPadding + self.bottomPadding)
    leftPadding: 24
    rightPadding: 24
    topPadding: 8
    bottomPadding: 8
    enabled: !self.disabled
    focusPolicy: Qt.StrongFocus
    hoverEnabled: true
    Accessible.role: Accessible.PageTab
    Accessible.name: self.text
    Accessible.checked: self.checked

    contentItem: UiLabel {
        // Bound width so elide/wrap can shrink long labels without painting into neighbors.
        width: self.availableWidth
        text: self.text
        typography: Theme.typography.labelLSemibold
        color: self.labelColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: self.wrapMode
        elide: self.elide
        Accessible.ignored: true
    }

    // Focus ring outside the control so focus does not change tab size.
    background: Item {
        id: tab_background
        Rectangle {
            anchors.fill: tab_background
            anchors.margins: -2
            color: 'transparent'
            border.width: 2
            border.color: self.colors.borderFocus
            radius: 4
            visible: self.enabled && self.visualFocus
        }
        Rectangle {
            anchors.left: tab_background.left
            anchors.right: tab_background.right
            anchors.bottom: tab_background.bottom
            height: 2
            color: self.colors.borderBrand
            visible: self.checked
        }
    }
}
