import Blockstream.Theme
import QtQuick
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts

Basic.TextField {
    enum Size { Large, Medium, Small }

    signal cleared()

    property string iconName: ''
    property Item leadingItem: null
    property Item trailingItem: null
    property int size: UiTextField.Large
    property bool disabled: false
    property bool clearable: true
    property string errorMessage: ''
    property bool invalid: false
    property Colors colors: Theme.colors

    readonly property bool hasError: self.invalid || self.errorMessage.length > 0
    readonly property bool clearVisible: self.clearable && self.enabled && !self.readOnly && self.length > 0
    readonly property Item leadingFocusItem: {
        const item = self.leadingItem
        return item?.visible && item.enabled && item.activeFocusOnTab ? item : null
    }
    readonly property Item trailingFocusItem: {
        const item = self.trailingItem
        return item?.visible && item.enabled && item.activeFocusOnTab ? item : null
    }
    property real fieldHeight: {
        if (self.size === UiTextField.Small) return 36
        if (self.size === UiTextField.Medium) return 44
        return 60
    }
    property real edgePadding: self.size === UiTextField.Large ? 16 : 12
    property real actionCenterY: self.fieldHeight / 2
    readonly property real errorHeight: error_panel.revealProgress * error_panel.implicitHeight

    property color backgroundColor: self.colors.surfaceBase

    property real borderWidth: 1
    property color borderColor: {
        if (self.hasError) return self.colors.feedbackNegativeStroke
        if (!self.enabled) return self.colors.borderSubtle
        if (self.activeFocus || clear_button.activeFocus || self.leadingItem?.activeFocus || self.trailingItem?.activeFocus) {
            return self.colors.borderBrand
        }
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
    leftPadding: self.edgePadding + (leading_host.width > 0 ? leading_host.width + 8 : 0)
    rightPadding: self.edgePadding + trailing_host.width + (trailing_host.width > 0 ? 8 : 0) + (self.clearVisible ? clear_button.width + 8 : 0)
    // Reserve the error panel below the native editor, including its placeholder.
    bottomPadding: self.padding + self.errorHeight
    Accessible.description: self.errorMessage
    // Include field actions even when macOS tabs only to text controls.
    KeyNavigation.tab: {
        if (self.leadingFocusItem) return self.leadingFocusItem
        if (self.trailingFocusItem) return self.trailingFocusItem
        return self.clearVisible ? clear_button : null
    }

    ActionSlot {
        id: leading_host
        item: self.leadingItem
        x: self.edgePadding
        y: self.actionCenterY - height / 2
        width: self.leadingItem?.visible ? self.leadingItem.width : leading_icon.visible ? leading_icon.width : 0
        height: self.leadingItem?.height ?? 20

        UiIcon {
            id: leading_icon
            visible: !self.leadingItem && name.length > 0
            name: self.iconName
            size: 20
            color: self.colors.iconSubtle
        }
    }
    ActionSlot {
        id: trailing_host
        item: self.trailingItem
        x: self.width - self.edgePadding - width  - (self.clearVisible ? clear_button.width : 0)
        y: self.actionCenterY - height / 2
        width: self.trailingItem?.visible ? self.trailingItem.width : 0
        height: self.trailingItem?.height ?? 0
    }

    component ActionSlot: Item {
        property Item item: null
        property Item hostedItem: null

        id: slot
        onItemChanged: {
            // Detach outgoing actions without destroying caller-owned objects.
            if (slot.hostedItem?.parent === slot) slot.hostedItem.parent = null
            slot.hostedItem = slot.item
            if (slot.item) slot.item.parent = slot
        }
    }
    Binding {
        target: self.trailingItem
        property: 'KeyNavigation.tab'
        value: self.trailingFocusItem && self.clearVisible ? clear_button : null
        when: self.trailingItem !== null
    }
    Binding {
        target: self.trailingItem
        property: 'KeyNavigation.backtab'
        value: self.trailingFocusItem ? (self.leadingFocusItem ?? self) : null
        when: self.trailingItem !== null
    }
    Binding {
        target: self.leadingItem
        property: 'KeyNavigation.tab'
        value: {
            if (!self.leadingFocusItem) return null
            if (self.trailingFocusItem) return self.trailingFocusItem
            return self.clearVisible ? clear_button : null
        }
        when: self.leadingItem !== null
    }
    Binding {
        target: self.leadingItem
        property: 'KeyNavigation.backtab'
        value: self.leadingFocusItem ? self : null
        when: self.leadingItem !== null
    }

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
            color: self.backgroundColor
            border.color: self.borderColor
            border.width: self.borderWidth
            radius: 8
        }
    }

    UiIconButton {
        id: clear_button
        Accessible.id: self.clearable && self.Accessible.id ? self.Accessible.id + '_clear_btn' : ''
        x: self.width - self.edgePadding / 2 - width
        y: self.actionCenterY - height / 2
        width: height
        size: self.size === UiTextField.Small ? UiButton.ExtraSmall : UiButton.Small
        iconName: Theme.icons.xCircle
        variant: UiButton.Neutral
        colors: self.colors
        text: qsTrId('id_clear')
        visible: self.clearVisible
        disabled: !self.clearVisible
        KeyNavigation.backtab: {
            if (!self.clearVisible) return null
            return self.trailingFocusItem ?? self.leadingFocusItem ?? self
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
