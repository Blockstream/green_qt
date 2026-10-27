import Blockstream.Theme
import QtQuick
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

Basic.TextArea {
    signal cleared()

    property alias actions: actions_host.data
    property bool clearable: true
    property Colors colors: Theme.colors
    property bool disabled: false
    property string errorMessage: ''
    property bool invalid: false
    readonly property bool hasError: self.invalid || self.errorMessage.length > 0
    readonly property real errorHeight: error_panel.revealProgress * error_panel.implicitHeight
    readonly property real fieldHeight: self.background.height - self.errorHeight
    readonly property bool clearVisible: self.clearable && self.enabled && !self.readOnly && self.length > 0
    readonly property real actionsHeight: action_row.visible ? action_row.height + 8 : 0
    readonly property color borderColor: {
        if (self.hasError) return self.colors.feedbackNegativeStroke
        if (!self.enabled) return self.colors.borderSubtle
        if (self.activeFocus || actions_host.activeFocus || clear_button.activeFocus) return self.colors.borderBrand
        if (self.hovered) return self.colors.borderBold
        return self.colors.borderSubtle
    }
    id: self
    enabled: !self.disabled
    implicitWidth: 280
    implicitHeight: Math.max(128, self.contentHeight + self.topPadding + self.bottomPadding - self.errorHeight) + self.errorHeight
    padding: 12
    bottomPadding: 12 + self.actionsHeight + self.errorHeight
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
    Keys.onTabPressed: event => {
        if (event.modifiers & Qt.ControlModifier) {
            event.accepted = false
            return
        }
        nextItemInFocusChain()?.forceActiveFocus(Qt.TabFocusReason)
    }
    onClearVisibleChanged: {
        if (!self.clearVisible && clear_button.activeFocus && self.enabled) self.forceActiveFocus()
    }

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
    Item {
        // Qt reparents the background to the viewport for a scrollable TextArea.
        // Host the footer beside it so actions and validation stay outside the text.
        parent: self.background.parent
        x: self.background.x
        y: self.background.y
        width: self.background.width
        height: self.background.height
        z: 1
        enabled: self.enabled
        visible: self.visible
        opacity: parent === self ? 1 : self.opacity
        clip: true

        Rectangle {
            // Only cover the text column; leave the rounded border unobscured.
            x: self.leftPadding
            y: self.fieldHeight - self.actionsHeight - self.padding
            width: Math.max(0, parent.width - self.leftPadding - self.rightPadding)
            height: self.actionsHeight + self.padding - 1
            color: self.colors.surfaceBase
            visible: action_row.visible
        }
        Rectangle {
            x: self.leftPadding
            y: self.fieldHeight
            width: Math.max(0, parent.width - self.leftPadding - self.rightPadding)
            height: Math.max(0, self.errorHeight - 1)
            color: self.colors.feedbackNegativeFill
        }

        RowLayout {
            id: action_row
            x: self.leftPadding / 2
            y: self.fieldHeight - self.rightPadding / 2 - action_row.height
            width: Math.max(0, self.width - self.leftPadding / 2 - self.rightPadding / 2)
            height: Math.max(action_row.implicitHeight, self.clearable ? 36 : 0)
            visible: actions_host.children.length > 0 || self.clearable
            spacing: 8

            FocusScope {
                id: actions_host
                implicitWidth: actions_host.childrenRect.width
                implicitHeight: actions_host.childrenRect.height
                visible: actions_host.children.length > 0
            }
            Item {
                Layout.fillWidth: true
            }
            UiIconButton {
                id: clear_button
                Accessible.id: self.clearable && self.Accessible.id ? self.Accessible.id + '_clear_btn' : ''
                text: qsTrId('id_clear')
                iconName: Theme.icons.xCircle
                variant: UiButton.Neutral
                size: UiButton.Small
                colors: self.colors
                visible: self.clearVisible
                onClicked: {
                    if (!self.clearVisible) return
                    self.clear()
                    self.forceActiveFocus()
                    self.cleared()
                }
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
}
