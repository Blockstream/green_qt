import QtQuick
import QtQuick.Controls

ProgressBar {
    property real _indeterminate_anim
    property real _indeterminate_position: self.visualPosition + Math.abs(2 * self._indeterminate_anim - 1) * (1 - self.visualPosition)
    NumberAnimation on _indeterminate_anim {
        from: 0
        to: 1
        running: self.indeterminate
        duration: 2000
        loops: Animation.Infinite
        easing.type: Easing.InOutCubic
    }
    id: self
    background: Rectangle {
        border.color: '#262626'
        border.width: 1
        color: '#181818'
        implicitHeight: 8
        opacity: 0.8
        radius: 4
    }
    contentItem: Item {
        implicitHeight: 8
        Rectangle {
            color: '#00BCFF'
            height: 8
            radius: 4
            x: (self.indeterminate ? (0.5 - 0.5 * self._indeterminate_position) : 0) * self.contentItem.width
            width: (self.indeterminate ? self._indeterminate_position : self.visualPosition) * self.contentItem.width
        }
    }
}
