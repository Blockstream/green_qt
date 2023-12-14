import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Canvas {
    property int current
    property int max
    property real progress: 0

    Component.onCompleted: progress = Qt.binding(() => Math.min(1, self.current / self.max))

    property bool indeterminate: false

    property int centerX: width / 2
    property int centerY: height / 2
    property int radius: Math.min(centerX, centerY) - 1

    property real startAngle: 0
    property real sweepAngle: Math.PI * 2 * (indeterminate ? 0.9 : progress)
    Behavior on sweepAngle {
        SmoothedAnimation {
            velocity: 3
        }
    }
    NumberAnimation on startAngle {
        loops: Animation.Infinite
        alwaysRunToEnd: true
        running: indeterminate
        from: 0
        to: Math.PI * 2
        duration: 1000
    }

    onStartAngleChanged: requestPaint()
    onSweepAngleChanged: requestPaint()

    id: self
    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height)
        ctx.lineWidth = 1
        ctx.strokeStyle = '#FFF'
        ctx.beginPath()
        ctx.arc(centerX, centerY, radius, startAngle - Math.PI / 2, startAngle +  sweepAngle - Math.PI / 2)
        ctx.stroke()
    }
}
