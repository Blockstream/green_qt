import QtQuick
import QtQuick.Controls

ListView {
    id: self
    ScrollIndicator.vertical: ScrollIndicator {
    }
    clip: true
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.min(self.height, 120)
        gradient: Gradient {
            GradientStop { position: 0; color: '#13161D' }
            GradientStop { position: 1; color: Qt.rgba(19/256, 22/256, 29/256, 0) }
        }
        opacity: Math.max(0, Math.min(self.contentY / 120, 1))
    }
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.min(self.height, 120)
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(19/256, 22/256, 29/256, 0) }
            GradientStop { position: 1; color: '#13161D' }
        }
        opacity: Math.max(0, Math.min((self.contentHeight - (self.contentY + (self.height - self.bottomMargin))) / 120, 1))
    }
}
