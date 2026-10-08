import Blockstream.Controls
import Blockstream.Theme
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    required property Colors colors
    readonly property var orientations: [
        { name: 'Horizontal', value: Qt.Horizontal },
        { name: 'Vertical', value: Qt.Vertical }
    ]
    readonly property var weights: [
        { name: 'Subtle', value: UiDivider.Subtle },
        { name: 'Bold', value: UiDivider.Bold }
    ]
    readonly property int playgroundOrientation: self.orientations[orientation_selector.currentIndex]?.value ?? Qt.Horizontal
    readonly property int playgroundWeight: self.weights[weight_selector.currentIndex]?.value ?? UiDivider.Subtle

    id: self
    spacing: 24
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        UiLabel {
            text: 'UiDivider'
            typography: Theme.typography.titleSSemibold
            color: self.colors.textPrimary
        }
        UiLabel {
            Layout.fillWidth: true
            text: 'A 1px non-interactive separator. Its length follows the containing layout.'
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
                    id: orientation_selector
                    Layout.fillWidth: true
                    model: self.orientations
                    textRole: 'name'
                    Accessible.name: 'Divider orientation'
                }
                ComboBox {
                    id: weight_selector
                    Layout.fillWidth: true
                    model: self.weights
                    textRole: 'name'
                    Accessible.name: 'Divider weight'
                }
                Slider {
                    id: size_slider
                    Layout.fillWidth: true
                    from: 0.2
                    to: 1
                    value: 1
                    Accessible.name: 'Container size'
                }
            }
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                Rectangle {
                    id: playground_area
                    width: self.playgroundOrientation === Qt.Horizontal ? parent.width * size_slider.value : parent.width
                    height: self.playgroundOrientation === Qt.Vertical ? parent.height * size_slider.value : parent.height
                    color: 'transparent'
                    border.width: 1
                    border.color: self.colors.borderSubtle
                    radius: 4
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8
                        visible: self.playgroundOrientation === Qt.Horizontal
                        SampleText { text: 'Above' }
                        UiDivider {
                            colors: self.colors
                            weight: self.playgroundWeight
                        }
                        SampleText { text: 'Below' }
                        Item { Layout.fillHeight: true }
                    }
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12
                        visible: self.playgroundOrientation === Qt.Vertical
                        SampleText { text: 'Left' }
                        UiDivider {
                            colors: self.colors
                            orientation: Qt.Vertical
                            weight: self.playgroundWeight
                        }
                        SampleText { text: 'Right' }
                        Item { Layout.fillWidth: true }
                    }
                }
            }
            UiLabel {
                text: `Container: ${Math.round(size_slider.value * 100)}%`
                typography: Theme.typography.bodyS
                color: self.colors.textSubtle
            }
        }
    }
    GalleryCard {
        contentItem: ColumnLayout {
            spacing: 8
            UiLabel {
                text: 'Variants'
                typography: Theme.typography.labelLSemibold
                color: self.colors.textPrimary
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                uniformCellSizes: true
                VariantPreview {
                    title: 'Dark'
                    previewColors: Theme.darkColors
                }
                VariantPreview {
                    title: 'Light'
                    previewColors: Theme.lightColors
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

    component SampleText: UiLabel {
        typography: Theme.typography.bodyM
        color: self.colors.textPrimary
    }

    component VariantPreview: Pane {
        required property string title
        required property Colors previewColors

        id: preview
        Layout.fillWidth: true
        padding: 12
        background: Rectangle {
            color: preview.previewColors.surfaceBase
            border.color: preview.previewColors.borderSubtle
            radius: 6
        }
        contentItem: ColumnLayout {
            spacing: 12
            UiLabel {
                text: preview.title
                typography: Theme.typography.labelMMedium
                color: preview.previewColors.textPrimary
            }
            VariantHeader { colors: preview.previewColors; text: 'Horizontal · Subtle' }
            UiDivider { colors: preview.previewColors }
            VariantHeader { colors: preview.previewColors; text: 'Horizontal · Bold' }
            UiDivider { colors: preview.previewColors; weight: UiDivider.Bold }
            RowLayout {
                Layout.preferredHeight: 48
                spacing: 12
                VariantHeader { colors: preview.previewColors; text: 'Vertical · Subtle' }
                UiDivider { colors: preview.previewColors; orientation: Qt.Vertical }
                VariantHeader { colors: preview.previewColors; text: 'Vertical · Bold' }
                UiDivider { colors: preview.previewColors; orientation: Qt.Vertical; weight: UiDivider.Bold }
            }
        }
    }

    component VariantHeader: UiLabel {
        property Colors colors: Theme.colors

        id: header
        typography: Theme.typography.bodyS
        color: header.colors.textSubtle
    }
}
