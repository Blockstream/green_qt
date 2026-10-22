import Blockstream.Theme
import QtQuick
import QtQuick.Controls.Basic as Basic

Basic.ComboBox {
    property Colors colors: Theme.colors
    property bool disabled: false
    id: self
    enabled: !self.disabled
    editable: false
    implicitWidth: 240
    implicitHeight: 44
    padding: 12
    rightPadding: 40
    font: Theme.typography.labelM.font
    focusPolicy: Qt.StrongFocus
    hoverEnabled: true
    contentItem: UiLabel {
        text: self.displayText
        typography: Theme.typography.labelM
        color: self.enabled ? self.colors.textPrimary : self.colors.textDisabled
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    indicator: UiIcon {
        x: self.width - width - 12
        y: (self.height - height) / 2
        name: Theme.icons.caretUpDown
        size: 20
        color: self.enabled ? self.colors.iconBase : self.colors.iconDisabled
    }
    background: Rectangle {
        radius: 8
        color: self.colors.surfaceBase
        border.color: self.visualFocus ? self.colors.borderFocus : self.hovered ? self.colors.borderBold : self.colors.borderSubtle
    }
    delegate: UiMenuItem {
        required property var model
        required property int index
        width: list.width
        text: model[self.textRole || 'modelData']
        colors: self.colors
        highlighted: self.highlightedIndex === index
        checkable: true
        autoExclusive: true
        checked: self.currentIndex === index
    }
    popup: Basic.Popup {
        y: self.height + 4
        width: self.width
        height: Math.min(300, list.contentHeight + topPadding + bottomPadding)
        padding: 1
        contentItem: ListView {
            id: list
            clip: true
            implicitHeight: contentHeight
            model: self.delegateModel
            currentIndex: self.highlightedIndex
            highlightMoveDuration: 0
            onCurrentIndexChanged: if (currentIndex >= 0) positionViewAtIndex(currentIndex, ListView.Contain)
            Basic.ScrollBar.vertical: UiScrollBar {
                colors: self.colors
            }
        }
        background: UiPopupSurface {
            colors: self.colors
        }
    }
}
