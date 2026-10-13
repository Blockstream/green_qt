import Blockstream.Controls
import Blockstream.Theme
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    required property Colors colors

    id: self
    spacing: 24
    UiLabel {
        text: 'UiDivider'
        typography: Theme.typography.titleSSemibold
        color: self.colors.textPrimary
    }
    Pane {
        Layout.fillWidth: true
        padding: 12
        background: Rectangle {
            color: self.colors.surfaceBase
            border.color: self.colors.borderSubtle
            radius: 6
        }
        contentItem: ColumnLayout {
            spacing: 12
            Caption { text: 'Subtle horizontal' }
            UiDivider {
                colors: self.colors
            }
            Caption { text: 'Bold horizontal' }
            UiDivider {
                colors: self.colors
                weight: UiDivider.Bold
            }
            RowLayout {
                Layout.preferredHeight: 48
                spacing: 12
                Caption { text: 'Subtle vertical' }
                UiDivider {
                    colors: self.colors
                    orientation: Qt.Vertical
                }
                Caption { text: 'Bold vertical' }
                UiDivider {
                    colors: self.colors
                    orientation: Qt.Vertical
                    weight: UiDivider.Bold
                }
            }
        }
    }

    component Caption: UiLabel {
        typography: Theme.typography.bodyS
        color: self.colors.textSubtle
    }
}
