import Blockstream.Green
import QtMultimedia
import QtQml
import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtQuick.Shapes

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
        videoOutput: video_output
    }

    VideoOutput {
        id: video_output
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
    }

    Item {
        anchors.centerIn: self
        scale: Math.max(self.width / video_output.sourceRect.width, self.height / video_output.sourceRect.height)
        width: video_output.sourceRect.width
        height: video_output.sourceRect.height

        Repeater {
            model: detector.results
            delegate: Shape {
                ShapePath {
                    fillColor: Qt.alpha('#00B45A', 0.25)
                    startX: modelData.points[0].x
                    startY: modelData.points[0].y
                    strokeColor: Qt.alpha('#00B45A', 0.75)
                    strokeWidth: 10
                    joinStyle: ShapePath.RoundJoin
                    PathLine {
                        x: modelData.points[1].x
                        y: modelData.points[1].y
                    }
                    PathLine {
                        x: modelData.points[2].x
                        y: modelData.points[2].y
                    }
                    PathLine {
                        x: modelData.points[3].x
                        y: modelData.points[3].y
                    }
                    PathLine {
                        x: modelData.points[0].x
                        y: modelData.points[0].y
                    }
                }
            }
        }
    }

    ZXingDetector {
        id: detector
        videoSink: video_output.videoSink
        onResultsChanged: {
            for (const result of detector.results) {
                self.codeScanned(result.text)
            }
        }
    }
}
