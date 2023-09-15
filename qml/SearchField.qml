import QtQuick
import QtQuick.Controls

TextField {
    leftPadding: 20
    rightPadding: 40 + search_image.width
    topPadding: 20
    bottomPadding: 20
    background: Rectangle {
        radius: 4
        color: '#2F2F35'
        Image {
            id: search_image
            source: 'qrc:/svg2/search.svg'
            anchors.margins: 20
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
        }
    }

}
