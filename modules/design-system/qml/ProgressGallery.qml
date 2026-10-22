import Blockstream.Controls
import Blockstream.Theme
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    required property Colors colors

    id: self
    spacing: 24
    UiLabel {
        text: 'UiSlider'
        typography: Theme.typography.titleSSemibold
        color: self.colors.textPrimary
    }
    UiSlider {
        id: slider
        Layout.fillWidth: true
        colors: self.colors
        from: 0
        to: 100
        value: 50
        stepSize: 5
    }
    UiLabel {
        text: 'Value: ' + slider.value
        typography: Theme.typography.bodyM
        color: self.colors.textPrimary
    }
    UiSlider {
        Layout.fillWidth: true
        colors: self.colors
        value: 0.5
        disabled: true
    }

    UiLabel {
        text: 'UiProgressBar'
        typography: Theme.typography.titleSSemibold
        color: self.colors.textPrimary
    }
    UiLabel {
        text: 'Measured'
        typography: Theme.typography.bodyM
        color: self.colors.textPrimary
    }
    UiProgressBar {
        Layout.fillWidth: true
        colors: self.colors
        value: 0.5
    }
    UiLabel {
        text: 'Indeterminate'
        typography: Theme.typography.bodyM
        color: self.colors.textPrimary
    }
    UiProgressBar {
        Layout.fillWidth: true
        colors: self.colors
        indeterminate: true
    }

    UiLabel {
        text: 'UiCircularProgress'
        typography: Theme.typography.titleSSemibold
        color: self.colors.textPrimary
    }
    RowLayout {
        spacing: 24
        UiCircularProgress {
            colors: self.colors
            value: 0
            diameter: 40
            strokeWidth: 3
        }
        UiCircularProgress {
            colors: self.colors
            value: 0.5
            diameter: 40
            strokeWidth: 3
        }
        UiCircularProgress {
            colors: self.colors
            value: 1
            diameter: 40
            strokeWidth: 3
        }
    }
}
