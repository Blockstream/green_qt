import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    Constants {
        id: constants
    }
    focus: StackLayout.isCurrentItem
    focusPolicy: Qt.ClickFocus
    background: Rectangle {
        color: '#121416'
    }
    clip: true
    leftPadding: constants.p3
    rightPadding: constants.p3
}
