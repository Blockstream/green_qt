import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

Canvas {
    required property int current
    required property int max

    property int centerX: width / 2
    property int centerY: height / 2
    property int radius: Math.min(centerX, centerY) - 5

    property real sweepAngle: Math.PI * 2 * (current / max)
    Behavior on sweepAngle {
        SmoothedAnimation {
            velocity: 6
        }
    }

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
        ctx.arc(centerX, centerY, radius, -Math.PI / 2, sweepAngle - Math.PI / 2)
        ctx.stroke()
    }

    Loader {
        opacity: 1 - check_image.opacity
        active: self.current < self.max
        anchors.centerIn: parent
        sourceComponent: RowLayout {
            spacing: 0
            Label {
                text: Math.min(self.current, self.max)
                font.pixelSize: 16
                font.family: 'Roboto'
                font.styleName: 'Light'
            }
            Label {
                Layout.alignment: Qt.AlignBottom
                text: '/' + self.max
                font.pixelSize: 12
                font.family: 'Roboto'
                font.styleName: 'Light'
            }
        }
    }

    Image {
        id: check_image
        opacity: self.current < self.max ? 0 : 1
        Behavior on opacity {
            NumberAnimation {
                easing.type: Easing.OutCubic
                duration: 500
            }
        }

        source: 'qrc:/svg/check.svg'
        anchors.centerIn: parent
        sourceSize.width: 24
        sourceSize.height: 24
    }
}
