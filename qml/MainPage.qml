import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    focus: StackLayout.isCurrentItem
    focusPolicy: Qt.ClickFocus
    background: Rectangle {
        color: '#121416'
    }
    clip: true
    leftPadding: 24
    rightPadding: 24
    // TODO: avoid the following warning
    //   QML Page: Binding loop detected for property "implicitWidth"
    // main page size is defined by the parent, so it is safe to define
    // the implicit width for now
    implicitWidth: 0
}
