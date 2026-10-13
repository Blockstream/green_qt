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
        text: 'UiLink'
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
            UiLink {
                colors: self.colors
                text: 'Large link'
                url: 'https://help.blockstream.com/'
            }
            UiLink {
                colors: self.colors
                size: UiLink.Medium
                text: 'Medium link'
                url: 'https://help.blockstream.com/'
            }
        }
    }
}
