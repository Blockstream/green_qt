import Blockstream.Theme
import QtQuick
import QtQuick.Controls.Basic as Basic

Basic.TextArea {
    property Colors colors: Theme.colors
    property bool disabled: false
    property string errorMessage: ''
    readonly property bool hasError: self.errorMessage.length > 0
    readonly property real errorHeight: error_panel.revealProgress * error_panel.implicitHeight
    readonly property real fieldHeight: self.height - self.errorHeight
    readonly property color borderColor: {
        if (self.hasError) return self.colors.feedbackNegativeStroke
        if (!self.enabled) return self.colors.borderSubtle
        if (self.activeFocus) return self.colors.borderBrand
        if (self.hovered) return self.colors.borderBold
        return self.colors.borderSubtle
    }
    id: self
    enabled: !self.disabled
    implicitWidth: 280
    implicitHeight: Math.max(100, contentHeight + topPadding + 12) + self.errorHeight
    padding: 12
    bottomPadding: 12 + self.errorHeight
    wrapMode: TextEdit.Wrap
    selectByMouse: true
    hoverEnabled: true
    clip: true
    font: Theme.typography.bodyM.font
    color: self.enabled ? self.colors.textPrimary : self.colors.textDisabled
    placeholderTextColor: self.colors.textSubtle
    selectionColor: self.colors.textBrand
    selectedTextColor: self.colors.textInverse
    Accessible.description: self.errorMessage
    background: Rectangle {
        color: self.hasError || error_panel.revealProgress > 0 ? self.colors.feedbackNegativeFill : self.colors.surfaceBase
        radius: 8
        border.color: self.hasError || error_panel.revealProgress > 0 ? self.colors.feedbackNegativeStroke : self.borderColor
        Rectangle {
            width: parent.width
            height: self.fieldHeight
            radius: 8
            color: self.colors.surfaceBase
            border.color: self.borderColor
        }
    }
    Row {
        readonly property string sourceMessage: self.errorMessage
        // Keep the text until collapse finishes, even after the caller clears it.
        property string displayedMessage: ''
        property bool expanded: false
        property real revealProgress: error_panel.expanded ? 1 : 0

        onSourceMessageChanged: {
            if (error_panel.sourceMessage) {
                error_panel.displayedMessage = error_panel.sourceMessage
                error_timer.restart()
            } else {
                error_panel.expanded = false
                error_timer.stop()
            }
        }

        id: error_panel
        y: self.fieldHeight
        width: self.width
        padding: 12
        spacing: 4
        visible: error_panel.revealProgress > 0
        Behavior on revealProgress {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }
        Timer {
            id: error_timer
            interval: 120
            onTriggered: error_panel.expanded = true
        }
        UiIcon {
            id: error_icon
            size: 16
            name: Theme.icons.warningDiamondFilled
            color: self.colors.feedbackNegativeAccent
        }
        UiLabel {
            width: Math.max(0, error_panel.width - 2 * error_panel.padding - error_icon.width - error_panel.spacing)
            text: error_panel.displayedMessage
            typography: Theme.typography.labelSm
            color: self.colors.textPrimary
            wrapMode: Text.Wrap
            textFormat: Text.PlainText
            Accessible.ignored: true
        }
    }
}
