import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ListView {
    property bool refreshGesture: false
    property alias refreshText: refresh_label.text
    signal refreshTriggered()

    id: self
    contentWidth: vertical_scroll_bar.visible ? width - constants.p0 * 2 : width
    MouseArea {
        anchors.fill: parent
        onClicked: forceActiveFocus(Qt.MouseFocusReason)
        z: -1
    }

    onContentYChanged: {
        if (self.refreshGesture && dragging) {
            if (contentY < -32) {
                if (refresh_label.scale === 0) {
                    show_refresh_animation.start()
                }
            } else {
                refresh_label.scale = 0
                show_refresh_animation.stop()
            }
        }
    }

    NumberAnimation {
        id: show_refresh_animation
        target: refresh_label
        property: 'scale'
        to: 1
        easing.type: Easing.OutBack
        duration: 400
    }

    Label {
        id: refresh_label
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.margins: constants.p1
        text: qsTrId('id_refresh')
        scale: 0
        padding: 8
        leftPadding: 16
        rightPadding: 16
        background: Rectangle {
            radius: height / 2
            color: constants.g500
        }
        font.pixelSize: 10
        font.weight: 400
        font.styleName: 'Regular'
    }

    onDraggingChanged: {
        if (self.refreshGesture) {
            show_refresh_animation.stop()
            refresh_label.scale = 0
            if (!dragging && self.contentY < -32) {
                self.refreshTriggered()
            }
        }
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
