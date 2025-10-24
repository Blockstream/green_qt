import QtQuick
import QtQuick.Controls

Item {
    property string text
    property real radius: 16
    property real border: 8
    property bool corners: false
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
            source: `image://zxing/${encodeURI(self.text || '')}`
        }
        Clip {
            anchors.left: parent.left
            anchors.top: parent.top
            Border {
                anchors.left: parent.left
                anchors.top: parent.top
            }
        }
        Clip {
            anchors.right: parent.right
            anchors.top: parent.top
            Border {
                anchors.right: parent.right
                anchors.top: parent.top
            }
        }
        Clip {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            Border {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
            }
        }
        Clip {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            Border {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
            }
        }
    }

    component Clip: Item {
        anchors.margins: -12
        clip: true
        height: 32
        visible: self.corners
        width: 32
    }

    component Border: Rectangle {
        width: 64
        height: 64
        border.width: 4
        border.color: '#00BCFF'
        color: 'transparent'
        radius: self.radius + 12
    }
}
