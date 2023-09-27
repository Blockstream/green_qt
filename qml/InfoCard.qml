import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Pane {
    property alias icon: icon_image.source
    property alias title: title_label.text
    property alias description: description_label.text

    Layout.topMargin: 10
    Layout.fillWidth: true
    Layout.maximumWidth: 325
    background: Rectangle {
        radius: 4
        color: '#222226'
    }
    leftPadding: 50
    rightPadding: 50
    contentItem: ColumnLayout {
        Image {
            Layout.alignment: Qt.AlignCenter
            id: icon_image
        }
        Label {
            Layout.fillWidth: true
            id: title_label
            color: '#FFF'
            font.family: 'SF Compact Display'
            font.pixelSize: 14
            font.weight: 700
            horizontalAlignment: Qt.AlignHCenter
            text: 'Safe Environment'
            wrapMode: Label.WordWrap
        }
        Label {
            Layout.fillWidth: true
            id: description_label
            color: '#FFF'
            opacity: 0.6
            font.family: 'SF Compact Display'
            font.pixelSize: 12
            font.weight: 400
            horizontalAlignment: Qt.AlignHCenter
            wrapMode: Label.WordWrap
        }
    }
}
