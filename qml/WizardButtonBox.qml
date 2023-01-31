import QtQuick
import QtQuick.Controls

DialogButtonBox {
    property StackView stackView
    Repeater {
        model: stackView.currentItem ? stackView.currentItem.actions : []
        GButton {
            large: true
            action: modelData
        }
    }
}
