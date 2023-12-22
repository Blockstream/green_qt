import QtQuick
import QtQuick.Controls

Item {
    property string text
    property real radius: 16
    property real border: 8
    readonly property int size: Math.min(self.width, self.height)

    id: self
    implicitHeight: 160
    implicitWidth: 160
    Rectangle {
        anchors.centerIn: parent
        color: 'white'
        radius: self.radius
        width: self.size
        height: self.size
        Image {
            id: img
            anchors.fill: parent
            anchors.margins: self.border
            fillMode: Image.PreserveAspectFit
            horizontalAlignment: Image.AlignHCenter
            verticalAlignment: Image.AlignVCenter
            smooth: false
            mipmap: false
            cache: false
            sourceSize.width: img.width
            sourceSize.height: img.height
            source: `image://QZXing/encode/${escape(self.text || '')}?format=qrcode&border=false&transparent=false&correctionLevel=H`
        }
    }
}
