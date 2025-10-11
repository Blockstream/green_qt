import QtQuick

GMenu {
    id: popup
    x: (parent?.width ?? 0) - popup.width
    y: (parent?.height ?? 0) + 8
    padding: 8
    spacing: 4
    pointerX: 1
    pointerXOffset: -(parent?.width ?? 0) / 2
}
