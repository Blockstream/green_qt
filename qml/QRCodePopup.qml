import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.15
import QtQuick.Shapes 1.0

Popup {
    id: self
    required property string text
    component BallonPath: ShapePath {
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

    background: MouseArea {
        hoverEnabled: true
    }
    x: parent.width / 2 - width / 2
    y: -height
    contentItem: Loader {
        active: self.visible
        sourceComponent: Item {
            implicitWidth: 200
            implicitHeight: 216
            scale: self.background.containsMouse ? 1.05 : (self.visible ? 1 : 0)
            transformOrigin: Item.Bottom
            Behavior on scale {
                NumberAnimation {
                    easing.type: Easing.OutBack
                    duration: 400
                }
            }
            Shape {
                anchors.fill: parent
                BallonPath {
                    strokeWidth: 0
                    fillColor: 'white'
                }
            }
            Rectangle {
                id: qrcode
                anchors.fill: parent
                color: 'white'
                Image {
                    fillMode: Image.PreserveAspectFit
                    horizontalAlignment: Image.AlignHCenter
                    verticalAlignment: Image.AlignVCenter
                    smooth: false
                    mipmap: false
                    cache: false
                    anchors.fill: parent
                    anchors.margins: 8
                    anchors.bottomMargin: 16
                    sourceSize.width: width
                    sourceSize.height: height
                    source: `image://QZXing/encode/${escape(self.text || '')}?format=qrcode&border=true&transparent=false`
                }
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Shape {
                        width: qrcode.width
                        height: qrcode.height
                        BallonPath {
                            strokeWidth: 1
                            strokeColor: 'transparent'
                            fillColor: 'white'
                        }
                    }
                }
            }
            Shape {
                anchors.fill: parent
                layer.samples: 4
                BallonPath {
                    strokeColor: constants.g400
                    strokeWidth: 1
                    fillColor: 'transparent'
                }
            }
        }
    }
}
