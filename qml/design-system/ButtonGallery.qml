import Blockstream.Controls
import Blockstream.Theme
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    required property Colors colors
    property int clickCount: 0
    readonly property var variants: [
        { name: 'Primary', value: UiButton.Primary },
        { name: 'Secondary', value: UiButton.Secondary },
        { name: 'Tertiary', value: UiButton.Tertiary },
        { name: 'Negative', value: UiButton.Negative },
        { name: 'Primary inverted', value: UiButton.PrimaryInverted },
        { name: 'Secondary inverted', value: UiButton.SecondaryInverted }
    ]
    readonly property var sizes: [
        { name: 'Large · 56px', value: UiButton.Large },
        { name: 'Medium · 48px', value: UiButton.Medium },
        { name: 'Small · 40px', value: UiButton.Small },
        { name: 'Extra small · 32px', value: UiButton.ExtraSmall }
    ]

    id: self
    spacing: 24
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        UiLabel {
            text: 'UiButton'
            typography: Theme.typography.titleSSemibold
            color: self.colors.textPrimary
        }
        UiLabel {
            Layout.fillWidth: true
            text: 'Hover or press a button, or use Tab to inspect keyboard focus.'
            typography: Theme.typography.bodyS
            color: self.colors.textSubtle
            wrapMode: Text.Wrap
        }
    }
    GalleryCard {
        contentItem: ColumnLayout {
            spacing: 8
            UiLabel {
                text: 'Playground'
                typography: Theme.typography.labelLSemibold
                color: self.colors.textPrimary
            }
            RowLayout {
                Layout.fillWidth: true
                ComboBox {
                    id: variant_selector
                    Layout.fillWidth: true
                    model: self.variants
                    textRole: 'name'
                    Accessible.name: 'Button variant'
                }
                ComboBox {
                    id: size_selector
                    Layout.fillWidth: true
                    model: self.sizes
                    textRole: 'name'
                    currentIndex: 1
                    Accessible.name: 'Button size'
                }
                TextField {
                    id: button_text
                    Layout.fillWidth: true
                    text: 'Continue'
                    selectByMouse: true
                    Accessible.name: 'Button text'
                }
            }
            Flow {
                Layout.fillWidth: true
                spacing: 8
                CheckBox {
                    id: leading_icon
                    text: 'Leading icon'
                }
                CheckBox {
                    id: trailing_icon
                    text: 'Trailing icon'
                }
                CheckBox {
                    id: button_disabled
                    text: 'Disabled'
                }
                CheckBox {
                    id: button_busy
                    text: 'Loading'
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                UiButton {
                    Layout.maximumWidth: parent.width - click_count.implicitWidth - parent.spacing
                    colors: self.colors
                    text: button_text.text
                    variant: self.variants[variant_selector.currentIndex]?.value ?? UiButton.Primary
                    size: self.sizes[size_selector.currentIndex]?.value ?? UiButton.Medium
                    iconName: leading_icon.checked ? Theme.icons.check : ''
                    trailingIconName: trailing_icon.checked ? Theme.icons.copy : ''
                    disabled: button_disabled.checked
                    busy: button_busy.checked
                    onClicked: self.clickCount++
                }
                UiLabel {
                    id: click_count
                    Layout.fillWidth: true
                    text: `Clicks: ${self.clickCount}`
                    typography: Theme.typography.bodyS
                    color: self.colors.textSubtle
                }
            }
        }
    }
    GalleryCard {
        contentItem: ColumnLayout {
            spacing: 24
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                UiLabel {
                    text: 'Variants · Medium'
                    typography: Theme.typography.labelLSemibold
                    color: self.colors.textPrimary
                }
                Flow {
                    Layout.fillWidth: true
                    spacing: 12
                    Repeater {
                        model: self.variants
                        UiButton {
                            required property var modelData

                            id: variant_sample
                            text: variant_sample.modelData.name
                            colors: self.colors
                            variant: variant_sample.modelData.value
                            onClicked: self.clickCount++
                        }
                    }
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                UiLabel {
                    text: 'Sizes and states · Primary'
                    typography: Theme.typography.labelLSemibold
                    color: self.colors.textPrimary
                }
                Flow {
                    Layout.fillWidth: true
                    spacing: 16
                    Repeater {
                        model: self.sizes.concat([
                            { name: 'Disabled', value: UiButton.Medium, disabled: true },
                            { name: 'Loading', value: UiButton.Medium, busy: true }
                        ])
                        Column {
                            required property var modelData

                            id: specimen
                            spacing: 4
                            UiLabel {
                                text: specimen.modelData.name
                                typography: Theme.typography.bodyS
                                color: self.colors.textSubtle
                            }
                            UiButton {
                                text: 'Button'
                                colors: self.colors
                                size: specimen.modelData.value
                                disabled: specimen.modelData.disabled ?? false
                                busy: specimen.modelData.busy ?? false
                                onClicked: self.clickCount++
                            }
                        }
                    }
                }
            }
        }
    }

    component GalleryCard: Pane {
        Layout.fillWidth: true
        padding: 12
        background: Rectangle {
            color: self.colors.surfaceBase
            border.color: self.colors.borderSubtle
            radius: 6
        }
    }
}
