import Blockstream.Theme
import QtQuick
import QtQuick.Shapes
import QtQuick.Controls.Basic as Basic

Basic.ProgressBar {
    property Colors colors: Theme.colors
    property real diameter: 24
    property real strokeWidth: 2
    id: self
    implicitWidth: self.diameter
    implicitHeight: self.diameter
    padding: 0
    background: null
    Accessible.role: Accessible.ProgressBar
    contentItem: Shape {
        id: ring
        readonly property real radius: Math.max(0, (Math.min(width, height) - self.strokeWidth) / 2)

        preferredRendererType: Shape.CurveRenderer
        visible: ring.radius > 0 && self.strokeWidth > 0
        ShapePath {
            fillColor: 'transparent'
            strokeColor: self.colors.surfaceSunken
            strokeWidth: self.strokeWidth
            capStyle: ShapePath.FlatCap
            PathAngleArc {
                centerX: ring.width / 2
                centerY: ring.height / 2
                radiusX: ring.radius
                radiusY: ring.radius
                startAngle: -90
                sweepAngle: 360
            }
        }
        ShapePath {
            fillColor: 'transparent'
            strokeColor: self.enabled ? self.colors.actionPrimary : self.colors.actionDisabled
            strokeWidth: self.strokeWidth
            capStyle: ShapePath.FlatCap
            PathAngleArc {
                centerX: ring.width / 2
                centerY: ring.height / 2
                radiusX: ring.radius
                radiusY: ring.radius
                startAngle: -90
                sweepAngle: self.position * 360
            }
        }
    }
}
