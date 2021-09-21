import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12
import QtMultimedia 5.13
import QtGraphicalEffects 1.15
import QtQuick.Shapes 1.0

Popup {
    id: self

    readonly property bool available: QtMultimedia.availableCameras.length > 0
    signal codeScanned(string code)

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
            implicitWidth: 300
            implicitHeight: 200
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
                    fillColor: constants.c700
                }
            }
            ScannerView {
                anchors.fill: parent
                id: scanner_view
                onCodeScanned: {
                    self.codeScanned(code)
                    self.close()
                }
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Shape {
                        width: scanner_view.width
                        height: scanner_view.height
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
            ToolButton {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 8
                hoverEnabled: false
                flat: true
                icon.source: 'qrc:/svg/cancel.svg'
                icon.width: 16
                icon.height: 16
                onClicked: self.close()
            }
        }
    }
}
