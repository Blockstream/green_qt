import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

GMenu {
    id: popup
    x: (parent?.width ?? 0) - popup.width
    y: (parent?.height ?? 0) + 8
    padding: 8
    spacing: 4
    pointerX: 1
    pointerXOffset: -(parent?.width ?? 0) / 2

    component SectionLabel: Label {
        Layout.fillWidth: true
        Layout.topMargin: 2
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        Layout.preferredWidth: 0
        opacity: 0.8
        font.pixelSize: 10
        elide: Label.ElideRight
    }

    component Separator: Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        Layout.topMargin: 2
        Layout.bottomMargin: 2
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        color: '#FFF'
        radius: 8
        opacity: 0.2
        visible: true
    }
}
