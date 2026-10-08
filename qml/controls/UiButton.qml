import Blockstream.Theme
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractButton {
    enum Variant { Primary, Secondary, Tertiary, Negative, PrimaryInverted, SecondaryInverted }
    enum Size { Large, Medium, Small, ExtraSmall }

    property int variant: UiButton.Primary
    property int size: UiButton.Medium
    property bool disabled: false
    property bool busy: false
    property string iconName: ""
    property string trailingIconName: ""
    property Colors colors: Theme.colors

    readonly property TypographyStyle typography: self.size === UiButton.ExtraSmall ? Theme.typography.labelSmSemibold : Theme.typography.labelLSemibold
    readonly property real buttonHeight: self.size === UiButton.Large ? 56 : self.size === UiButton.Small ? 40 : self.size === UiButton.ExtraSmall ? 32 : 48
    readonly property real iconSize: self.size === UiButton.Large ? 24 : 20

    readonly property bool interactionPressed: self.enabled && !self.busy && self.down
    readonly property bool interactionHovered: self.enabled && !self.busy && !self.interactionPressed && !self.visualFocus && self.hovered

    readonly property color foregroundColor: {
        if (!self.enabled && !self.busy) return self.colors.textDisabled
        if (self.variant === UiButton.Negative) return self.interactionPressed ? self.colors.feedbackNegativeOnFill : self.colors.feedbackNegativeAccent
        if (self.variant === UiButton.PrimaryInverted) return self.colors.actionOnPrimaryInverted
        if (self.variant === UiButton.SecondaryInverted) return self.colors.borderInverse
        if (self.variant === UiButton.Primary && !self.interactionPressed) return self.colors.actionOnPrimary
        return self.interactionHovered ? self.colors.textBrandHover : self.colors.textBrand
    }

    readonly property color surfaceColor: {
        if (!self.enabled && !self.busy) return self.colors.actionDisabled
        if (self.variant === UiButton.PrimaryInverted) return self.colors.actionPrimaryInverted
        if (self.variant === UiButton.SecondaryInverted) return 'transparent'
        if (self.variant === UiButton.Negative) return self.interactionPressed ? self.colors.feedbackNegativeAccent : self.interactionHovered ? self.colors.feedbackNegativeFill : 'transparent'
        if (self.interactionPressed) return self.colors.actionPressed
        if (self.variant === UiButton.Primary) return self.interactionHovered ? self.colors.actionHover : self.colors.actionPrimary
        return 'transparent'
    }

    readonly property color outlineColor: {
        if (!self.enabled && !self.busy) return 'transparent'
        if (self.variant === UiButton.Secondary) return self.interactionHovered ? self.colors.textBrandHover : self.colors.borderBrand
        if (self.variant === UiButton.Negative) return self.colors.feedbackNegativeAccent
        if (self.variant === UiButton.SecondaryInverted) return self.colors.borderInverse
        return 'transparent'
    }

    id: self
    implicitWidth: self.implicitContentWidth + self.leftPadding + self.rightPadding
    implicitHeight: self.buttonHeight
    enabled: !self.disabled && !self.busy
    focusPolicy: Qt.StrongFocus
    hoverEnabled: true
    font: self.typography.font
    spacing: self.size === UiButton.ExtraSmall ? 4 : 8
    leftPadding: self.size === UiButton.Large ? 24 : self.size === UiButton.ExtraSmall ? 12 : 16
    rightPadding: self.leftPadding
    topPadding: (self.buttonHeight - self.typography.lineHeight) / 2
    bottomPadding: self.topPadding
    Accessible.name: self.text
    Accessible.description: self.busy ? qsTrId('id_loading') : ''

    background: Item {
        id: button_background
        Rectangle {
            anchors.fill: button_background
            color: 'transparent'
            border.width: 2
            border.color: self.colors.borderFocus
            radius: 8
            visible: self.enabled && self.visualFocus
        }
        Rectangle {
            anchors.fill: button_background
            anchors.margins: self.enabled && self.visualFocus ? 4 : 0
            color: self.surfaceColor
            border.width: self.outlineColor.a > 0 ? 1 : 0
            border.color: self.outlineColor
            radius: self.enabled && self.visualFocus ? 4 : 8
        }
    }

    contentItem: Item {
        id: button_content_item
        // Opacity keeps the original content measurements while the spinner is shown.
        implicitWidth: button_content.implicitWidth
        implicitHeight: button_content.implicitHeight
        RowLayout {
            id: button_content
            anchors.centerIn: button_content_item
            width: Math.min(button_content.implicitWidth, button_content_item.width)
            spacing: self.spacing
            opacity: self.busy ? 0 : 1
            UiIcon {
                name: self.iconName
                size: self.iconSize
                color: self.foregroundColor
            }
            UiLabel {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Accessible.ignored: true
                text: self.text
                typography: self.typography
                color: self.foregroundColor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
            }
            UiIcon {
                name: self.trailingIconName
                size: self.iconSize
                color: self.foregroundColor
            }
        }
        UiSpinner {
            anchors.centerIn: button_content_item
            size: self.iconSize
            color: self.foregroundColor
            running: self.busy
        }
    }
}
