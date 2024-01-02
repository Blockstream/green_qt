import QtQuick

Item {
    required property string foreground
    property string background: 'qrc:/png/background.png'
    id: self
    clip: true
    Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        source: self.background
    }
    Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        mipmap: true
        source: self.foreground
    }
}
