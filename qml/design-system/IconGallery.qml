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
        TextField {
            id: search_input
            Layout.preferredWidth: 240
            Layout.preferredHeight: 32
            font: Theme.typography.bodyS.font
            leftPadding: 8
            rightPadding: 8
            topPadding: 4
            bottomPadding: 4
            color: self.colors.textPrimary
            placeholderText: 'Search icons'
            placeholderTextColor: self.colors.textSubtle
            selectByMouse: true
            Accessible.name: 'Search icons'
        }
    }
    UiLabel {
        visible: self.filteredIcons.length === 0
        text: 'No matching icons'
        typography: Theme.typography.bodyS
        color: self.colors.textSubtle
    }
    GridLayout {
        id: icon_grid
        Layout.fillWidth: true
        columns: 4
        columnSpacing: 12
        rowSpacing: 4
        uniformCellWidths: true
        Repeater {
            model: self.filteredIcons
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
