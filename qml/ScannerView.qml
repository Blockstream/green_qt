import QtMultimedia 5.13
import QtQuick 2.14
import QtQml 2.14
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.12
import QtQuick.Window 2.12
import QZXing 2.3

Item {
    id: self

    property alias source: video_output.source
    property list<Action> actions: [
        Action {
            text: qsTrId('id_back')
            onTriggered: cancel()
        }
    ]

    signal cancel()
    signal codeScanned(string code)

    BusyIndicator {
        anchors.centerIn: parent
        hoverEnabled: false
    }

    VideoOutput {
        id: video_output
        anchors.fill: parent
        autoOrientation: true
        fillMode: VideoOutput.PreserveAspectCrop
        source: Camera {
            Binding on cameraState {
                restoreMode: Binding.RestoreBindingOrValue
                value: Camera.UnloadedState
                when: !window.active
            }
            focus {
                focusMode: CameraFocus.FocusContinuous
                focusPointMode: CameraFocus.FocusPointAuto
            }
        }

        filters: QZXingFilter {
            captureRect: {
                video_output.width;
                video_output.height;
                video_output.contentRect;
                video_output.sourceRect;
                return video_output.mapRectToSource(video_output.mapNormalizedRectToItem(Qt.rect(0, 0, 1, 1)));
            }

            decoder {
                tryHarder: true
                enabledDecoders: QZXing.DecoderFormat_QR_CODE
                onTagFound: codeScanned(tag)
            }
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
