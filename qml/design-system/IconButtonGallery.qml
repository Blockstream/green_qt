import Blockstream.Controls
import Blockstream.Theme
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    required property Colors colors
    readonly property var variants: [
        { name: 'Default', value: UiButton.Tertiary },
        { name: 'Primary', value: UiButton.Primary },
        { name: 'Secondary', value: UiButton.Secondary }
    ]
    readonly property var sizes: [
        { name: 'Large · 56px', value: UiButton.Large },
        { name: 'Medium · 40px', value: UiButton.Medium },
        { name: 'Small · 36px', value: UiButton.Small },
        { name: 'Extra small · 28px', value: UiButton.ExtraSmall }
    ]

    id: self
    spacing: 24
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        UiLabel {
            text: 'UiIconButton'
            typography: Theme.typography.titleSSemibold
            color: self.colors.textPrimary
        }
        UiLabel {
            Layout.fillWidth: true
            text: 'Icon-only actions. Hover, press, or use Tab to inspect focus. The action name is read by assistive technology.'
            typography: Theme.typography.bodyS
            color: self.colors.textSubtle
            wrapMode: Text.Wrap
        }
    }
    GalleryCard {
        contentItem: ColumnLayout {
            spacing: 24
            UiLabel {
                text: 'Variants and sizes'
                typography: Theme.typography.labelLSemibold
                color: self.colors.textPrimary
            }
            Flow {
                Layout.fillWidth: true
                spacing: 24
                Repeater {
                    model: self.variants
                    Column {
                        required property var modelData

                        id: variant_sample
                        spacing: 8
                        UiLabel {
                            text: variant_sample.modelData.name
                            typography: Theme.typography.bodyS
                            color: self.colors.textSubtle
                        }
                        Row {
                            spacing: 8
                            Repeater {
                                model: self.sizes
                                UiIconButton {
                                    required property var modelData

                                    id: size_sample
                                    colors: self.colors
                                    text: 'Copy address'
                                    iconName: Theme.icons.copy
                                    variant: variant_sample.modelData.value
                                    size: size_sample.modelData.value
                                }
                            }
                        }
                        UiLabel {
                            text: '56 / 40 / 36 / 28px'
                            typography: Theme.typography.bodyS
                            color: self.colors.textSubtle
                        }
                    }
                }
            }
            UiLabel {
                text: 'Disabled and loading · Medium'
                typography: Theme.typography.labelLSemibold
                color: self.colors.textPrimary
            }
            Flow {
                Layout.fillWidth: true
                spacing: 24
                Repeater {
                    model: self.variants
                    Column {
                        required property var modelData

                        id: state_sample
                        spacing: 8
                        UiLabel {
                            text: state_sample.modelData.name
                            typography: Theme.typography.bodyS
                            color: self.colors.textSubtle
                        }
                        Row {
                            spacing: 8
                            UiIconButton {
                                colors: self.colors
                                text: 'Copy address'
                                iconName: Theme.icons.copy
                                variant: state_sample.modelData.value
                                disabled: true
                            }
                            UiIconButton {
                                colors: self.colors
                                text: 'Copy address'
                                iconName: Theme.icons.copy
                                variant: state_sample.modelData.value
                                busy: true
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
