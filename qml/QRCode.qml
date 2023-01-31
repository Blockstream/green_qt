import QtQuick

Item {
    property string text

    implicitHeight: 120
    implicitWidth: 120

    Image {
        fillMode: Image.PreserveAspectFit
        horizontalAlignment: Image.AlignHCenter
        verticalAlignment: Image.AlignVCenter
        smooth: false
        mipmap: false
        cache: false
        anchors.centerIn: parent
        sourceSize.width: parent.implicitWidth
        sourceSize.height: parent.implicitHeight
        source: `image://QZXing/encode/${escape(text || '')}?format=qrcode&border=true&transparent=true`
    }
}
