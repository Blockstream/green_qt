import QtQuick
import QtQuick.Controls

TTextField {
    id: self
    leftPadding: 15 + search_image.width + 15
    Image {
        id: search_image
        source: 'qrc:/svg2/search.svg'
        anchors.leftMargin: 15
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
    }
    Label {
        text: qsTrId('id_search')
        opacity: 0.6
        visible: self.text === ''
        anchors.left: parent.left
        anchors.leftMargin: self.leftPadding
        anchors.baseline: parent.baseline
    }
}
