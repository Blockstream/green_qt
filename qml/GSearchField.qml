import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

GTextField {
    readonly property bool empty: text === ''
    id: self
    radius: height / 2
    leftPadding: height / 2 + contentHeight + 4
    rightPadding: self.empty ? height / 2 : clear_button.height + self.height - self.font.pixelSize
    Keys.onEscapePressed: self.clear()
    Image {
        source: 'qrc:/svg/search.svg'
        height: self.contentHeight + 4
        width: height
        smooth: true
        mipmap: true
        anchors.left: parent.left
        anchors.leftMargin: (self.height - self.font.pixelSize) / 2
        anchors.verticalCenter: parent.verticalCenter
    }
    Rectangle {
        id: clear_button
        visible: !self.empty
        anchors.right: parent.right
        anchors.rightMargin: (self.height - self.font.pixelSize) / 2
        anchors.verticalCenter: parent.verticalCenter
        height: self.contentHeight + 4
        width: height
        color: mouse_area.containsMouse ? constants.c400 : constants.c500
        radius: height / 2
        Image {
            anchors.fill: parent
            anchors.margins: 4
            fillMode: Image.PreserveAspectFit
            source: 'qrc:/svg/x.svg'
        }
        MouseArea {
            id: mouse_area
            anchors.fill: parent
            hoverEnabled: true
            onClicked: self.clear()
            cursorShape: Qt.ArrowCursor
        }
    }
}
