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
        text: 'UiTabs'
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
            UiTabs {
                id: account_tabs
                Layout.fillWidth: true
                UiTab {
                    colors: self.colors
                    text: 'Transactions'
                }
                UiTab {
                    colors: self.colors
                    text: 'Coins'
                }
                UiTab {
                    colors: self.colors
                    text: 'Addresses'
                }
                UiTab {
                    colors: self.colors
                    text: 'Disabled'
                    disabled: true
                }
            }
            UiLabel {
                text: `Selected: ${account_tabs.currentItem?.text ?? '-'}`
                typography: Theme.typography.bodyS
                color: self.colors.textSubtle
            }
            UiTabs {
                Layout.fillWidth: true
                UiTab {
                    colors: self.colors
                    width: 160
                    text: 'Very long tab label that should elide'
                    elide: Text.ElideRight
                }
                UiTab {
                    colors: self.colors
                    text: 'Short'
                }
            }
        }
    }
}
