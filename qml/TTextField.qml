import QtQuick
import QtQuick.Controls

TextField {
    property var error
    readonly property bool visualFocus: {
        if (!self.readOnly && self.activeFocus) {
            switch (self.focusReason) {
            case Qt.TabFocusReason:
            case Qt.BacktabFocusReason:
            case Qt.ShortcutFocusReason:
                return true
            }
        }
        return false
    }
    id: self
    topPadding: 14
    bottomPadding: 13
    leftPadding: 15
    background: Item {
        anchors.fill: parent
        Rectangle {
            anchors.fill: parent
            border.width: 2
            border.color: '#00BCFF'
            color: 'transparent'
            radius: 5
            visible: self.visualFocus
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: self.visualFocus ? 4 : 0
            border.width: !!self.error ? 2 : self.visualFocus ? 1 : 0
            border.color: !!self.error ? '#C91D36' : '#262626'
            color: Qt.lighter('#181818', !self.readOnly && self.hovered ? 1.2 : 1)
            radius: self.visualFocus ? 1 : 5
        }
    }
    font.pixelSize: 14
    font.weight: 500
    font.features: { 'calt': 0, 'zero': 1 }
}
