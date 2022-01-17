import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

Canvas {
    property int current
    property int max
    property real progress: Math.min(1, current / max)

    property bool indeterminate: false

    property int centerX: width / 2
    property int centerY: height / 2
    property int radius: Math.min(centerX, centerY) - 1

    property real startAngle: 0
    property real sweepAngle: Math.PI * 2 * (indeterminate ? 0.1 : progress)
    Behavior on sweepAngle {
        SmoothedAnimation {
            velocity: 6
        }
    }
    NumberAnimation on startAngle {
        loops: Animation.Infinite
        alwaysRunToEnd: true
        running: indeterminate
        from: 0
        to: Math.PI * 2
        duration: 1000
        //easing.type: Easing.OutCubic
    }

    onStartAngleChanged: requestPaint()
    onSweepAngleChanged: requestPaint()

    id: self
    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height)
        ctx.lineWidth = 1
        ctx.strokeStyle = constants.c500
        ctx.beginPath()
        ctx.arc(centerX, centerY, radius, 0, Math.PI * 2)
        ctx.stroke()
        ctx.strokeStyle = constants.g500
        ctx.beginPath()
        ctx.arc(centerX, centerY, radius, startAngle - Math.PI / 2, startAngle +  sweepAngle - Math.PI / 2)
        ctx.stroke()
    }
}
