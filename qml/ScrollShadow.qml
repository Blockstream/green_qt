import QtQuick 2.0

Rectangle {
    height: 16
    gradient: Gradient {
        GradientStop { position: 0.0; color: '#ff000000' }
        GradientStop { position: 1.0; color: '#00000000' }
    }
    opacity: parent.contentY > 8 ? 0.2 : 0
    width: parent.width
}
