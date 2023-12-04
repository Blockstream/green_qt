import QtQuick
import QtQuick.Controls

Rectangle {
    property string text
    readonly property int size: Math.min(self.width, self.height) - 16

    id: self
    implicitHeight: 160
    implicitWidth: 160
    color: 'white'
    radius: 16

    Image {
        id: img
        fillMode: Image.PreserveAspectFit
        horizontalAlignment: Image.AlignHCenter
        verticalAlignment: Image.AlignVCenter
        smooth: false
        mipmap: false
        cache: false
        anchors.centerIn: parent
        width: self.size
        height: self.size
        sourceSize.width: width //parent.implicitWidth - 128
        sourceSize.height: height // parent.implicitHeight - 128
        source: `image://QZXing/encode/${escape(text || '')}?format=qrcode&border=false&transparent=false`
    }
}
