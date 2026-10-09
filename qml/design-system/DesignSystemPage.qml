import Blockstream.Controls
import Blockstream.Theme
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import 'catalog.js' as Catalog

Page {
    readonly property Colors previewColors: palette_switch.checked ? Theme.darkColors : Theme.lightColors

    function hex(value) {
        function channel(number) { return Math.round(number * 255).toString(16).padStart(2, '0') }
        return '#' + (value.a < 1 ? channel(value.a) : '') + channel(value.r) + channel(value.g) + channel(value.b)
    }

    function styleDetails(style) {
        const capitalization = style.capitalization === Font.AllUppercase ? 'uppercase' : 'mixed case'
        return `${style.family}, ${style.pixelSize}px, weight ${style.weight}, line height ${style.lineHeight}px, spacing ${style.letterSpacing}px, ${capitalization}`
    }

    id: self
    title: 'Design system'
    focusPolicy: Qt.ClickFocus
    clip: true
    padding: 24
    implicitWidth: 0
    Material.theme: palette_switch.checked ? Material.Dark : Material.Light
    Material.background: previewColors.surfaceCanvas
    Material.foreground: previewColors.textPrimary
    Material.accent: previewColors.textBrand
    Material.primary: previewColors.actionPrimary
    background: Rectangle { color: self.previewColors.surfaceCanvas }
    contentItem: ColumnLayout {
        spacing: 16
        RowLayout {
            Layout.fillWidth: true
            UiLabel {
                Layout.fillWidth: true
                text: 'Design system'
                color: self.previewColors.textPrimary
                typography: Theme.typography.titleLBold
            }
            UiToggle {
                id: palette_switch
                checked: true
                colors: self.previewColors
                text: 'Dark preview'
            }
        }
        TabBar {
            Layout.alignment: Qt.AlignLeft
            id: tabs
            background: Item {}
            GalleryTab { text: 'Colors'; colors: self.previewColors }
            GalleryTab { text: 'Typography'; colors: self.previewColors }
            GalleryTab { text: 'Components'; colors: self.previewColors }
        }
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabs.currentIndex

            GalleryFlickable {
                Repeater {
                    model: Catalog.colorGroups
                    ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 6
                        UiLabel {
                            Layout.fillWidth: true
                            text: parent.modelData.title
                            color: self.previewColors.textPrimary
                            typography: Theme.typography.titleSSemibold
                        }
                        GridLayout {
                            property var tokens: parent.modelData.tokens
                            id: color_grid
                            Layout.fillWidth: true
                            columns: 3
                            columnSpacing: 12
                            rowSpacing: 12
                            uniformCellWidths: true
                            Repeater {
                                model: color_grid.tokens
                                delegate: PreviewCard {
                                    required property var modelData
                                    id: swatch_card
                                    contentItem: RowLayout {
                                        spacing: 12
                                        DesignSystemSwatch {
                                            value: self.previewColors[swatch_card.modelData.name]
                                            borderColor: self.previewColors.borderSubtle
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 4
                                            UiLabel {
                                                Layout.fillWidth: true
                                                text: swatch_card.modelData.designId
                                                wrapMode: Text.WrapAnywhere
                                                color: self.previewColors.textPrimary
                                                typography: Theme.typography.labelMMedium
                                            }
                                            UiLabel {
                                                Layout.fillWidth: true
                                                text: 'Theme.colors.' + swatch_card.modelData.name
                                                color: self.previewColors.textSubtle
                                                typography: Theme.typography.bodyS
                                                wrapMode: Text.WrapAnywhere
                                            }
                                            UiLabel {
                                                Layout.fillWidth: true
                                                text: self.hex(self.previewColors[swatch_card.modelData.name])
                                                color: self.previewColors.textSubtle
                                                typography: Theme.typography.codeS
                                                wrapMode: Text.WrapAnywhere
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                Item { Layout.fillHeight: true }
            }

            GalleryFlickable {
                SampleField {
                    id: typography_sample
                }
                Repeater {
                    model: Catalog.typographyGroups
                    ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 6
                        UiLabel {
                            Layout.fillWidth: true
                            text: parent.modelData.title
                            color: self.previewColors.textPrimary
                            typography: Theme.typography.titleSSemibold
                        }
                        Repeater {
                            model: parent.modelData.tokens
                            delegate: PreviewCard {
                                required property var modelData
                                readonly property TypographyStyle textStyle: Theme.typography[modelData.name]
                                id: specimen
                                contentItem: ColumnLayout {
                                    spacing: 8
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6
                                        UiLabel {
                                            text: specimen.modelData.designId
                                            color: self.previewColors.textPrimary
                                            typography: Theme.typography.labelLMedium
                                        }
                                        UiLabel {
                                            Layout.fillWidth: true
                                            text: `· Theme.typography.${specimen.modelData.name} · ${self.styleDetails(specimen.textStyle)}`
                                            color: self.previewColors.textSubtle
                                            typography: Theme.typography.bodyS
                                            wrapMode: Text.WrapAnywhere
                                        }
                                    }
                                    UiLabel {
                                        Layout.fillWidth: true
                                        text: typography_sample.text
                                        typography: specimen.textStyle
                                        color: self.previewColors.textPrimary
                                        wrapMode: Text.Wrap
                                    }
                                }
                            }
                        }
                    }
                }
                Item { Layout.fillHeight: true }
            }

            GalleryFlickable {
                UiLabel {
                    text: 'UiLabel'
                    color: self.previewColors.textPrimary
                    typography: Theme.typography.titleSSemibold
                }
                SampleField {
                    id: label_sample
                }
                Repeater {
                    model: [
                        { title: 'Single line', typography: 'bodyM', color: 'textPrimary', multiline: false },
                        { title: 'Wrapping', typography: 'titleLBold', color: 'textPrimary', multiline: true },
                        { title: 'Semantic color', typography: 'bodyM', color: 'feedbackNegativeAccent', multiline: true }
                    ]
                    PreviewCard {
                        required property var modelData
                        id: example
                        contentItem: ColumnLayout {
                            spacing: 8
                            UiLabel {
                                Layout.fillWidth: true
                                text: example.modelData.title
                                color: self.previewColors.textPrimary
                                typography: Theme.typography.bodyM
                            }
                            UiLabel {
                                Layout.fillWidth: true
                                text: `typography: Theme.typography.${example.modelData.typography}\ncolor: Theme.colors.${example.modelData.color}`
                                color: self.previewColors.textSubtle
                                typography: Theme.typography.codeS
                                wrapMode: Text.WrapAnywhere
                            }
                            UiLabel {
                                Layout.fillWidth: true
                                Layout.maximumWidth: example.modelData.multiline ? 420 : Infinity
                                text: label_sample.text
                                typography: Theme.typography[example.modelData.typography]
                                color: self.previewColors[example.modelData.color]
                                wrapMode: example.modelData.multiline ? Text.Wrap : Text.NoWrap
                                elide: example.modelData.multiline ? Text.ElideNone : Text.ElideRight
                            }
                        }
                    }
                }
                UiDivider {
                    Layout.topMargin: 20
                    Layout.bottomMargin: 20
                    colors: self.previewColors
                }
                ButtonGallery {
                    Layout.fillWidth: true
                    colors: self.previewColors
                }
                UiDivider {
                    Layout.topMargin: 20
                    Layout.bottomMargin: 20
                    colors: self.previewColors
                }
                IconButtonGallery {
                    Layout.fillWidth: true
                    colors: self.previewColors
                }
                UiDivider {
                    Layout.topMargin: 20
                    Layout.bottomMargin: 20
                    colors: self.previewColors
                }
                TextFieldGallery {
                    Layout.fillWidth: true
                    colors: self.previewColors
                }
                UiDivider {
                    Layout.topMargin: 20
                    Layout.bottomMargin: 20
                    colors: self.previewColors
                }
                IconGallery {
                    Layout.fillWidth: true
                    colors: self.previewColors
                }
                UiDivider {
                    Layout.topMargin: 20
                    Layout.bottomMargin: 20
                    colors: self.previewColors
                }
                RadioGallery {
                    Layout.fillWidth: true
                    colors: self.previewColors
                }
                UiDivider {
                    Layout.topMargin: 20
                    Layout.bottomMargin: 20
                    colors: self.previewColors
                }
                CheckboxGallery {
                    Layout.fillWidth: true
                    colors: self.previewColors
                }
                UiDivider {
                    Layout.topMargin: 20
                    Layout.bottomMargin: 20
                    colors: self.previewColors
                }
                ToggleGallery {
                    Layout.fillWidth: true
                    colors: self.previewColors
                }
                UiDivider {
                    Layout.topMargin: 20
                    Layout.bottomMargin: 20
                    colors: self.previewColors
                }
                DividerGallery {
                    Layout.fillWidth: true
                    colors: self.previewColors
                }
                Item { Layout.fillHeight: true }
            }
        }
    }

    component GalleryFlickable: Flickable {
        default property alias contentItemData: layout.data

        id: flickable
        clip: true
        contentWidth: flickable.width
        contentHeight: layout.height
        focusPolicy: Qt.ClickFocus
        ScrollIndicator.vertical: ScrollIndicator {}
        ColumnLayout {
            id: layout
            width: flickable.width
            height: Math.max(flickable.height, layout.implicitHeight)
            spacing: 12
        }
    }

    component SampleField: UiTextField {
        Layout.fillWidth: true
        colors: self.previewColors
        size: UiTextField.Medium
        text: 'The quick brown fox jumps over the lazy dog. 0123456789'
        Accessible.name: 'Sample text'
    }

    component GalleryTab: TabButton {
        required property Colors colors

        id: tab
        width: implicitWidth
        leftPadding: 16
        rightPadding: 16
        font: Theme.typography.labelLMedium.font
        contentItem: UiLabel {
            text: tab.text
            typography: Theme.typography.labelLMedium
            color: tab.checked ? tab.colors.textBrand : tab.colors.textPrimary
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            color: 'transparent'
            border.width: tab.visualFocus ? 1 : 0
            border.color: tab.colors.borderBrand
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 2
                visible: tab.checked
                color: tab.colors.borderBrand
            }
        }
    }

    component PreviewCard: Pane {
        Layout.fillWidth: true
        padding: 12
        background: Rectangle {
            color: self.previewColors.surfaceBase
            border.color: self.previewColors.borderSubtle
            radius: 6
        }
    }
}
