import Blockstream.Controls
import Blockstream.Theme
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    required property Colors colors
    readonly property var icons: Object.keys(Theme.icons)
        .filter(name => name !== 'objectName' && typeof Theme.icons[name] === 'string')
        .map(name => ({ name, value: Theme.icons[name] }))
    readonly property string searchQuery: search_input.text.trim().toLowerCase()
    readonly property var filteredIcons: self.icons.filter(icon => `Theme.icons.${icon.name}`.toLowerCase().includes(self.searchQuery))

    readonly property var brandIconNames: [Theme.icons.jade, Theme.icons.ledger]
    readonly property var filteredBrandIcons: self.filteredIcons.filter(icon => self.brandIconNames.includes(icon.value))
    readonly property var filteredUiIcons: self.filteredIcons.filter(icon => !self.brandIconNames.includes(icon.value))

    id: self
    spacing: 12

    RowLayout {
        Layout.fillWidth: true
        UiLabel {
            Layout.fillWidth: true
            text: self.searchQuery ? `UiIcon · ${self.filteredIcons.length} / ${self.icons.length}` : `UiIcon · ${self.icons.length}`
            typography: Theme.typography.titleSSemibold
            color: self.colors.textPrimary
        }
        UiTextField {
            id: search_input
            Layout.maximumWidth: 240
            colors: self.colors
            size: UiTextField.Small
            placeholderText: 'Search icons'
            Accessible.name: 'Search icons'
        }
    }
    UiLabel {
        visible: self.filteredIcons.length === 0
        text: 'No matching icons'
        typography: Theme.typography.bodyS
        color: self.colors.textSubtle
    }
    UiLabel {
        visible: self.filteredBrandIcons.length > 0
        text: 'Brand icons · original colors'
        typography: Theme.typography.labelLSemibold
        color: self.colors.textPrimary
    }
    GridLayout {
        id: brand_icon_grid
        visible: self.filteredBrandIcons.length > 0
        Layout.fillWidth: true
        columns: 4
        columnSpacing: 12
        rowSpacing: 4
        uniformCellWidths: true
        Repeater {
            model: self.filteredBrandIcons
            Rectangle {
                required property var modelData
                readonly property string iconExpression: `Theme.icons.${modelData.name}`

                id: brand_specimen
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.preferredWidth: Math.max(0, (self.width - 3 * brand_icon_grid.columnSpacing) / 4)
                Layout.maximumWidth: brand_specimen.Layout.preferredWidth
                implicitHeight: 36
                color: self.colors.surfaceBase
                radius: 4

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 2
                    spacing: 8
                    Rectangle {
                        implicitWidth: 24
                        implicitHeight: 24
                        color: Theme.darkColors.surfaceBase
                        radius: 4
                        UiIcon {
                            anchors.centerIn: parent
                            name: brand_specimen.modelData.value
                            size: 20
                            colorize: false
                        }
                    }
                    UiLabel {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        text: brand_specimen.iconExpression
                        typography: Theme.typography.codeS
                        color: self.colors.textSubtle
                        elide: Text.ElideRight
                        HoverHandler { id: brand_name_hover }
                        ToolTip.visible: brand_name_hover.hovered && truncated
                        ToolTip.text: brand_specimen.iconExpression
                    }
                    UiButton {
                        id: brand_copy_button
                        Layout.preferredWidth: 76
                        variant: UiButton.Tertiary
                        size: UiButton.ExtraSmall
                        colors: self.colors
                        text: brand_copied_timer.running ? 'Copied' : 'Copy'
                        Accessible.name: `${text} ${brand_specimen.iconExpression}`
                        onClicked: {
                            Clipboard.copy(brand_specimen.iconExpression)
                            brand_copied_timer.restart()
                        }
                        Timer {
                            id: brand_copied_timer
                            interval: 1200
                        }
                    }
                }
            }
        }
    }
    UiLabel {
        visible: self.filteredUiIcons.length > 0
        text: 'UI icons'
        typography: Theme.typography.labelLSemibold
        color: self.colors.textPrimary
    }
    GridLayout {
        id: icon_grid
        visible: self.filteredUiIcons.length > 0
        Layout.fillWidth: true
        columns: 4
        columnSpacing: 12
        rowSpacing: 4
        uniformCellWidths: true
        Repeater {
            model: self.filteredUiIcons
            Rectangle {
                required property var modelData
                readonly property string iconExpression: `Theme.icons.${modelData.name}`

                id: specimen
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.preferredWidth: Math.max(0, (self.width - 3 * icon_grid.columnSpacing) / 4)
                Layout.maximumWidth: specimen.Layout.preferredWidth
                implicitHeight: 36
                color: self.colors.surfaceBase
                radius: 4

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 2
                    spacing: 8
                    UiIcon {
                        name: specimen.modelData.value
                        size: 20
                        color: self.colors.iconBase
                    }
                    UiLabel {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        text: specimen.iconExpression
                        typography: Theme.typography.codeS
                        color: self.colors.textSubtle
                        elide: Text.ElideRight
                        HoverHandler { id: name_hover }
                        ToolTip.visible: name_hover.hovered && truncated
                        ToolTip.text: specimen.iconExpression
                    }
                    UiButton {
                        id: copy_button
                        Layout.preferredWidth: 76
                        variant: UiButton.Tertiary
                        size: UiButton.ExtraSmall
                        colors: self.colors
                        text: copied_timer.running ? 'Copied' : 'Copy'
                        Accessible.name: `${text} ${specimen.iconExpression}`
                        onClicked: {
                            Clipboard.copy(specimen.iconExpression)
                            copied_timer.restart()
                        }
                        Timer {
                            id: copied_timer
                            interval: 1200
                        }
                    }
                }
            }
        }
    }
}
