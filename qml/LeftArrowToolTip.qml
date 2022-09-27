import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.13
import QtQuick.Window 2.12
import QtGraphicalEffects 1.15
import QtQuick.Shapes 1.0

ToolTip {
    id: control
    delay: 10
    topPadding: 4
    bottomPadding: 4
    leftPadding: 16
    rightPadding: 12
    contentItem: Label {
        color: constants.c500
        font: control.font
        text: control.text
    }
    enter: null
    exit: null
    x: parent.width + 16
    y: parent.height / 2 - control.height / 2
    background: Shape {
        id: shape
        layer.samples: 4
        BallonPath {
            width: shape.width
            height: shape.height
            strokeColor: Qt.rgba(0, 0, 0, 0.5)
            strokeWidth: 1
            fillColor: 'white'
        }
    }
    component BallonPath: ShapePath {
        required property real width
        required property real height
        property real radius: height / 2
        startX: height / 2
        startY: 0
        PathAngleArc {
            moveToStart: false
            radiusX: radius
            radiusY: radius
            centerX: width - radius
            centerY: radius
            startAngle: -90
            sweepAngle: 90
        }
        PathAngleArc {
            moveToStart: false
            radiusX: radius
            radiusY: radius
            centerX: width - radius
            centerY: height - radius
            startAngle: 0
            sweepAngle: 90
        }
        PathLine {
            x: height / 2
            y: height
        }
        PathLine {
            x: 0
            y: height / 2
        }
        PathLine {
            x: height / 2
            y: 0
        }
    }
}
