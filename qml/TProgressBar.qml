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
        color: "#235B35"
        implicitHeight: 10
        radius: 5
    }
    contentItem: Item {
        implicitHeight: 10
        Rectangle {
            color: '#46B068'
            height: 10
            radius: 5
            x: (self.indeterminate ? (0.5 - 0.5 * self._indeterminate_position) : 0) * self.contentItem.width
            width: (self.indeterminate ? self._indeterminate_position : self.visualPosition) * self.contentItem.width
        }
    }
}
