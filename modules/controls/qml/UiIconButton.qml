import QtQuick

UiButton {
    id: self
    variant: UiButton.Tertiary
    buttonHeight: self.size === UiButton.Large ? 56 : self.size === UiButton.Small ? 36 : self.size === UiButton.ExtraSmall ? 28 : 40
    iconSize: self.size === UiButton.Large || self.size === UiButton.Medium ? 24 : self.size === UiButton.Small ? 20 : 16
    implicitWidth: self.buttonHeight
    implicitHeight: self.buttonHeight
    leftPadding: (self.buttonHeight - self.iconSize) / 2
    rightPadding: self.leftPadding
    topPadding: self.leftPadding
    bottomPadding: self.leftPadding
    spacing: 0

    contentItem: Item {
        id: button_content
        implicitWidth: self.iconSize
        implicitHeight: self.iconSize
        UiIcon {
            anchors.centerIn: button_content
            name: self.iconName
            size: self.iconSize
            color: self.foregroundColor
            opacity: self.busy ? 0 : 1
        }
        UiSpinner {
            anchors.centerIn: button_content
            size: self.iconSize
            color: self.foregroundColor
            running: self.busy
        }
    }
}
