import Blockstream.Controls
import Blockstream.Theme
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    required property Colors colors
    property int activations: 0

    id: self
    spacing: 24
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        UiLabel {
            text: 'UiCard / UiCardButton'
            typography: Theme.typography.titleSSemibold
            color: self.colors.textPrimary
        }
        UiLabel {
            Layout.fillWidth: true
            text: 'Hover the interactive card, then use Tab and Space to activate it. Focus should not move its content.'
            typography: Theme.typography.bodyS
            color: self.colors.textSubtle
            wrapMode: Text.Wrap
        }
    }
    UiCard {
        Layout.fillWidth: true
        colors: self.colors
        contentItem: ColumnLayout {
            spacing: 2
            UiLabel {
                text: 'Static content'
                typography: Theme.typography.labelLSemibold
                color: self.colors.textPrimary
            }
            UiLabel {
                Layout.fillWidth: true
                text: 'A card provides a surface and padding for caller-owned content.'
                typography: Theme.typography.bodyM
                color: self.colors.textSubtle
                wrapMode: Text.Wrap
            }
        }
    }
    UiToggle {
        id: disabled_toggle
        colors: self.colors
        text: 'Disable interactive card'
    }
    UiCardButton {
        id: interactive_card
        Layout.fillWidth: true
        implicitHeight: 72
        colors: self.colors
        disabled: disabled_toggle.checked
        text: 'Interactive card'
        onClicked: self.activations++
        contentItem: RowLayout {
            spacing: 12
            UiIcon {
                name: Theme.icons.wallet
                color: interactive_card.enabled ? self.colors.iconBase : self.colors.iconDisabled
            }
            UiLabel {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: interactive_card.text
                typography: Theme.typography.labelLMedium
                color: interactive_card.enabled ? self.colors.textPrimary : self.colors.textDisabled
                verticalAlignment: Text.AlignVCenter
            }
            UiIcon {
                name: Theme.icons.caretRight
                color: interactive_card.enabled ? self.colors.iconSubtle : self.colors.iconDisabled
            }
        }
    }
    UiLabel {
        text: `Activations: ${self.activations}`
        typography: Theme.typography.bodyS
        color: self.colors.textSubtle
    }
}
