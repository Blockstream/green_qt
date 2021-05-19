import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3

TextField {
    readonly property bool empty: text === ''
    id: self
    topInset: 4
    bottomInset: 4
    leftPadding: height / 2 + contentHeight
    rightPadding: self.empty ? height / 2 : clear_button.height + self.height - self.font.pixelSize
    topPadding: 12
    bottomPadding: 12
    background: Rectangle {
        radius: height / 2
        color: 'transparent'
        border.width: 1
        border.color: self.activeFocus ? constants.g700 : constants.c600
    }
    implicitWidth: self.activeFocus || !self.empty ? 300 : 200
    Behavior on implicitWidth {
        SmoothedAnimation {
            velocity: 800
        }
    }
    placeholderText: qsTrId('id_search')
    Keys.onEscapePressed: self.clear()
    Image {
        source: 'qrc:/svg/search.svg'
        height: self.contentHeight + 4
        width: height
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
