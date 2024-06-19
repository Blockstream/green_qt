import QtQuick

Item {
    required property string foreground
    property string background: 'qrc:/png/background.png'
    property bool fill: true
    property bool center: false
    id: self
    clip: true
    Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        source: self.background
    }
    Image {
        anchors.fill: self.fill ? parent : null
        anchors.centerIn: self.center ? parent : null
        fillMode: Image.PreserveAspectFit
        mipmap: true
        source: self.foreground
    }
}
