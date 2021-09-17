import QtQuick 2.15
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

ListView {
    id: self
    contentWidth: vertical_scroll_bar.visible ? width - constants.p0 * 2 : width
    MouseArea {
        anchors.fill: parent
        onClicked: forceActiveFocus(Qt.MouseFocusReason)
        z: -1
    }
    ScrollBar.vertical: ScrollBar {
        id: vertical_scroll_bar
        policy: ScrollBar.AlwaysOn
        visible: self.contentHeight > self.height
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
}
