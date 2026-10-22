import QtQuick
import QtQuick.Controls

Flickable {
    property var availableWidth: vertical_scroll_bar.visible ? width - 8 * 2 : width

    id: self
    contentWidth: width
    ScrollBar.vertical: ScrollBar {
        id: vertical_scroll_bar
        policy: ScrollBar.AlwaysOn
        visible: self.contentHeight > self.height
        background: Rectangle {
            color: '#12171E'
            radius: width / 2
        }
        contentItem: Rectangle {
            implicitWidth: 8
            color: vertical_scroll_bar.pressed ? '#475361' : '#23303E'
            radius: 8
        }
    }
    ScrollBar.horizontal: ScrollBar {
        id: horizontal_scroll_bar
        policy: ScrollBar.AlwaysOn
        visible: self.contentWidth > self.width
        background: Rectangle {
            color: '#12171E'
            radius: width / 2
        }
        contentItem: Rectangle {
            implicitHeight: 8
            color: horizontal_scroll_bar.pressed ? '#475361' : '#23303E'
            radius: 8
        }
    }

    Keys.onUpPressed: vertical_scroll_bar.decrease()
    Keys.onDownPressed: vertical_scroll_bar.increase()
    Keys.onLeftPressed: horizontal_scroll_bar.decrease()
    Keys.onRightPressed: horizontal_scroll_bar.increase()
}
