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
        text: 'UiScrollIndicator'
        typography: Theme.typography.titleSSemibold
        color: self.colors.textPrimary
    }
    Flickable {
        Layout.fillWidth: true
        Layout.preferredHeight: 120
        contentWidth: width
        contentHeight: indicator_label.implicitHeight
        clip: true
        UiLabel {
            id: indicator_label
            typography: Theme.typography.bodyM
            width: parent.width - 16
            text: Array.from({ length: 25 }, (_, index) => 'Scrollable row ' + index).join('\n')
            color: self.colors.textPrimary
        }
        ScrollIndicator.vertical: UiScrollIndicator {
            colors: self.colors
        }
    }

    UiLabel {
        text: 'UiScrollBar'
        typography: Theme.typography.titleSSemibold
        color: self.colors.textPrimary
    }
    Flickable {
        Layout.fillWidth: true
        Layout.preferredHeight: 120
        contentWidth: width
        contentHeight: bar_label.implicitHeight
        clip: true
        UiLabel {
            id: bar_label
            typography: Theme.typography.bodyM
            width: parent.width - 16
            text: Array.from({ length: 25 }, (_, index) => 'Scrollable row ' + index).join('\n')
            color: self.colors.textPrimary
        }
        ScrollBar.vertical: UiScrollBar {
            colors: self.colors
        }
    }
}
