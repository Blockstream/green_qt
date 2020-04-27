import QtQuick 2.3

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

        Binding on source {
            when: text.length > 0
            value: `image://QZXing/encode/${escape(text)}?format=qrcode&border=true&transparent=true`
        }
    }
}
