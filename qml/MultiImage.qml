import QtQuick

Item {
    required property string foreground
    property string background: 'qrc:/png/background.png'
    property bool fill: true
    property bool center: false
    property real margins: 0
    id: self
    Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        source: self.background
    }
    Image {
        anchors.fill: self.fill ? parent : null
        anchors.margins: self.margins
        anchors.centerIn: self.center ? parent : null
        fillMode: Image.PreserveAspectFit
        mipmap: true
        source: self.foreground
    }
}
