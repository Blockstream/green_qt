import QtQuick
import QtQuick.Shapes

ShapePath {
    startX: 16
    startY: 0
    PathAngleArc {
        moveToStart: false
        radiusX: 16
        radiusY: 16
        centerX: width - 16
        centerY: 16
        startAngle: -90
        sweepAngle: 90
    }
    PathAngleArc {
        moveToStart: false
        radiusX: 16
        radiusY: 16
        centerX: width - 16
        centerY: height - 16 - 8
        startAngle: 0
        sweepAngle: 90
    }
    PathLine {
        x: width / 2 + 8
        y: height - 8
    }
    PathLine {
        x: width / 2
        y: height
    }
    PathLine {
        x: width / 2 - 8
        y: height - 8
    }
    PathAngleArc {
        moveToStart: false
        radiusX: 16
        radiusY: 16
        centerX: 16
        centerY: height - 16 - 8
        startAngle: 90
        sweepAngle: 90
    }
    PathAngleArc {
        moveToStart: false
        radiusX: 16
        radiusY: 16
        centerX: 16
        centerY: 16
        startAngle: 180
        sweepAngle: 90
    }
}
