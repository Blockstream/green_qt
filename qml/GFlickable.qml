import QtQuick 2.15
import QtQuick.Controls 2.13

Flickable {
    property var availableWidth: vertical_scroll_bar.visible ? width - constants.p0 * 2 : width

    id: self
    contentWidth: width
    ScrollBar.vertical: ScrollBar {
        id: vertical_scroll_bar
        policy: ScrollBar.AlwaysOn
        visible: self.childrenRect.height > self.height
        background: Rectangle {
            color: constants.c800
            radius: width / 2
        }
        contentItem: Rectangle {
            implicitWidth: constants.p0
            color: vertical_scroll_bar.pressed ? constants.c400 : constants.c600
            radius: 8
        }
    }
    ScrollBar.horizontal: ScrollBar {
        id: horizontal_scroll_bar
        policy: ScrollBar.AlwaysOn
        visible: self.childrenRect.width > self.width
        background: Rectangle {
            color: constants.c800
            radius: width / 2
        }
        contentItem: Rectangle {
            implicitHeight: constants.p0
            color: horizontal_scroll_bar.pressed ? constants.c400 : constants.c600
            radius: 8
        }
    }

    Keys.onUpPressed: vertical_scroll_bar.decrease()
    Keys.onDownPressed: vertical_scroll_bar.increase()
    Keys.onLeftPressed: horizontal_scroll_bar.decrease()
    Keys.onRightPressed: horizontal_scroll_bar.increase()
}
