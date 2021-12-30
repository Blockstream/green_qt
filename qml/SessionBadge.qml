import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12
import QtQuick.Shapes 1.0

RowLayout {
    required property Session session
    readonly property bool connected: session && session.active && session.connected
    readonly property bool connecting: session && session.active && !session.connected

    Layout.fillWidth: false
    spacing: 12
    opacity: (connecting || connected) ? 1 : 0.5

    component ProgressCircle: Shape {
        id: self
        property real radius: Math.min(self.width, self.height) / 2
        property bool indeterminate: true
        property real progress: 0
        anchors.fill: parent
        anchors.margins: -4
        layer.samples: 4
        layer.enabled: true
        Behavior on opacity {
            SequentialAnimation {
                PauseAnimation {
                    duration: 1000
                }
                OpacityAnimator {
                }
            }
        }
        Rectangle {
            width: self.radius * 2
            height: self.radius * 2
            color: 'transparent'
            border.width: 1
            border.color: constants.c500
            anchors.centerIn: parent
            radius: self.radius
            z: -1
        }
        ShapePath {
            strokeWidth: 1
            strokeColor: constants.g300
            fillColor: 'transparent'
            PathAngleArc {
                moveToStart: true
                radiusX: self.radius - 0.5
                radiusY: self.radius - 0.5
                centerX: self.width / 2
                centerY: self.height / 2
                startAngle: -90
                NumberAnimation on startAngle {
                    loops: Animation.Infinite
                    alwaysRunToEnd: true
                    running: indeterminate
                    from: -90
                    to: 270
                    duration: 1000
                }
                sweepAngle: indeterminate ? 60 : progress * 360
                Behavior on sweepAngle {
                    SmoothedAnimation {
                        velocity: 360
                    }
                }
            }
        }
    }
    Image {
        smooth: true
        mipmap: true
        fillMode: Image.PreserveAspectFit
        horizontalAlignment: Image.AlignHCenter
        source: 'qrc:/svg/green_server.svg'
        sourceSize.height: 16
        ProgressCircle {
            indeterminate: connecting
            progress: connected ? 1 : 0
            opacity: connecting && progress < 1 ? 1 : 0
        }
    }
    Loader {
        active: session ? session.useTor : Settings.useTor
        visible: active
        sourceComponent: Image {
            smooth: true
            mipmap: true
            fillMode: Image.PreserveAspectFit
            horizontalAlignment: Image.AlignHCenter
            source: 'qrc:/svg/torV2.svg'
            sourceSize.height: 16
            ProgressCircle {
                indeterminate: connecting && progress === 0
                progress: {
                    if (connected) return 1
                    if (session && session.event.tor) return session.event.tor.progress * 0.01
                    return 0
                }
                opacity: connecting && progress < 1? 1 : 0
            }
        }
    }
}
