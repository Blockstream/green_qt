import QtQuick
import QtQuick.Controls

TextField {
    id: self
    leftPadding: 20
    rightPadding: 40 + search_image.width
    topPadding: 20
    bottomPadding: 20
    background: Rectangle {
        radius: 4
        color: '#2F2F35'
        Rectangle {
            border.width: 2
            border.color: '#00B45A'
            color: 'transparent'
            radius: 9
            anchors.fill: parent
            anchors.margins: -4
            z: -1
            visible: {
                if (self.activeFocus) {
                    switch (self.focusReason) {
                    case Qt.TabFocusReason:
                    case Qt.BacktabFocusReason:
                    case Qt.ShortcutFocusReason:
                        return true
                    }
                }
                return false
            }
        }
        Image {
            id: search_image
            source: 'qrc:/svg2/search.svg'
            anchors.margins: 20
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
        }
    }

}
