import Blockstream.Theme
import QtQuick
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

Basic.TextField {
    enum Size { Large, Medium, Small }

    signal cleared()

    property int size: UiTextField.Large
    property bool disabled: false
    property bool clearable: true
    property string errorMessage: ''
    property Colors colors: Theme.colors

    readonly property bool hasError: self.errorMessage.length > 0
    readonly property bool clearVisible: self.clearable && self.enabled && !self.readOnly && self.length > 0
    readonly property real fieldHeight: {
        if (self.size === UiTextField.Small) return 36
        if (self.size === UiTextField.Medium) return 44
        return 60
    }
    readonly property real errorHeight: error_panel.revealProgress * error_panel.implicitHeight

    readonly property color borderColor: {
        if (self.hasError) return self.colors.feedbackNegativeStroke
        if (!self.enabled) return self.colors.borderSubtle
        if (self.activeFocus || clear_button.activeFocus) return self.colors.borderBrand
        if (self.hovered) return self.colors.borderBold
        return self.colors.borderSubtle
    }

    id: self
    Layout.fillWidth: true
    implicitHeight: self.fieldHeight + self.errorHeight
    enabled: !self.disabled
    focusPolicy: Qt.StrongFocus
    hoverEnabled: true
    clip: true
    font: Theme.typography.labelM.font
    color: {
        if (!self.enabled) return self.colors.textDisabled
        if (self.hasError) return self.colors.textSubtle
        return self.colors.textPrimary
    }
    placeholderTextColor: self.enabled ? self.colors.textSubtle : self.colors.textDisabled
    selectionColor: self.colors.textBrand
    selectedTextColor: self.colors.textInverse
    padding: {
        if (self.size === UiTextField.Small) return 6
        if (self.size === UiTextField.Medium) return 8
        return 12
    }
    leftPadding: self.size === UiTextField.Large ? 16 : 12
    rightPadding: self.clearVisible ? self.leftPadding + clear_button.width + 8 : self.leftPadding
    // Reserve the error panel below the native editor, including its placeholder.
    bottomPadding: self.padding + self.errorHeight
    Accessible.description: self.errorMessage
    // Explicit navigation also reaches clear when macOS tabs only to text controls.
    KeyNavigation.tab: self.clearVisible ? clear_button : null

    background: Item {
        Rectangle {
            anchors.fill: parent
            visible: self.hasError || error_panel.revealProgress > 0
            color: self.colors.feedbackNegativeFill
            border.color: self.colors.feedbackNegativeStroke
            radius: 8
        }
        Rectangle {
            width: parent.width
            height: self.fieldHeight
            color: self.colors.surfaceBase
            border.color: self.borderColor
            radius: 8
        }
    }

    Basic.AbstractButton {
        id: clear_button
        x: self.width - width
        y: (self.fieldHeight - height) / 2
        width: height
        height: self.size === UiTextField.Small ? 36 : 44
        focusPolicy: Qt.StrongFocus
        hoverEnabled: true
        text: qsTrId('id_clear')
        visible: self.clearVisible
        enabled: self.clearVisible
        Accessible.name: clear_button.text
        KeyNavigation.backtab: self
        background: Rectangle {
            color: 'transparent'
            border.width: 2
            border.color: self.colors.borderFocus
            radius: 8
            visible: clear_button.enabled && clear_button.visualFocus
        }
        contentItem: Item {
            UiIcon {
                anchors.centerIn: parent
                name: Theme.icons.xCircle
                size: self.size === UiTextField.Small ? 16 : 20
                color: clear_button.hovered ? self.colors.textPrimary : self.colors.iconSubtle
            }
        }
        onClicked: {
            if (!self.clearVisible) return
            self.clear()
            self.forceActiveFocus()
            self.cleared()
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
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
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
