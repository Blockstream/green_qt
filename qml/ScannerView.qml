import QtMultimedia
import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Window
import QZXing

Item {
    signal codeScanned(string code)

    id: self

    BusyIndicator {
        anchors.centerIn: parent
        hoverEnabled: false
    }

    CaptureSession {
        camera: Camera {
            id: camera
            Component.onCompleted: camera.start()
        }
        videoOutput: videoOutput
    }

    VideoOutput {
        id: videoOutput
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
    }

    QZXingFilter
    {
        id: zxingFilter
        videoSink: videoOutput.videoSink
        orientation: videoOutput.orientation
        captureRect: {
            videoOutput.sourceRect;
            return Qt.rect(videoOutput.sourceRect.width * videoOutput.captureRectStartFactorX,
                           videoOutput.sourceRect.height * videoOutput.captureRectStartFactorY,
                           videoOutput.sourceRect.width * videoOutput.captureRectFactorWidth,
                           videoOutput.sourceRect.height * videoOutput.captureRectFactorHeight)
        }

        decoder {
            enabledDecoders: QZXing.DecoderFormat_QR_CODE
            onTagFound: self.codeScanned(tag)
            tryHarder: false
        }
    }

    Rectangle {
        border.width: 1
        border.color: Material.accent
        color: 'transparent'
        width: Math.min(parent.width, parent.height) - Math.round(self.width / 10)
        height: width
        anchors.centerIn: parent
        opacity: 0
        SequentialAnimation on opacity {
            PauseAnimation { duration: 2000 }
            SmoothedAnimation { to: 0.5; velocity: 2 }
        }

        Rectangle {
            color: Material.accent
            anchors.fill: parent
            anchors.margins: 8
            opacity: 0.1
        }
    }
}
