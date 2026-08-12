import Blockstream.Green
import Blockstream.Green.Core
import QtMultimedia
import QtCore
import QtQml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Window
import ZXing

Item {
    property Context context
    readonly property int bcurProgress: controller.progress
    readonly property bool permissionDenied: permission.status === Qt.Denied
    readonly property bool waitingForPermission: permission.status === Qt.Undetermined
    readonly property bool hasCamera: media_devices.videoInputs.length > 0
    readonly property bool cameraAvailable: !self.permissionDenied && self.hasCamera
    readonly property bool waitingForCamera: self.cameraAvailable && permission.status === Qt.Granted && !camera.active
    readonly property bool showCameraWarning: !self.cameraAvailable && !self.waitingForPermission
    property var barcodeOverlays: []
    signal codeScanned(string code)
    signal bcurScanned(var result)
    function start() {
        if (permission.status === Qt.Undetermined) {
            permission.request()
        }
    }
    function reset() {
        controller.reset()
    }

    id: self

    Component.onCompleted: self.start()

    // Tear the capture graph down deterministically: the loaders hosting this
    // view are deactivated while the camera is still running, and the V4L2
    // notifier delivering frames outlives the video sink it pushes them into.
    Component.onDestruction: {
        detector.videoSink = null
        camera.active = false
    }

    MediaDevices {
        id: media_devices
    }

    CameraPermission {
        id: permission
        onStatusChanged: self.start()
    }

    BusyIndicator {
        anchors.centerIn: parent
        hoverEnabled: false
        running: self.waitingForCamera || self.waitingForPermission
        visible: running
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 12
        visible: self.showCameraWarning
        width: Math.min(parent.width - 40, 280)
        Image {
            Layout.alignment: Qt.AlignHCenter
            source: 'qrc:/svg2/warning.svg'
        }
        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            horizontalAlignment: Label.AlignHCenter
            font.pixelSize: 14
            font.weight: 400
            opacity: 0.8
            wrapMode: Label.WordWrap
            text: self.permissionDenied ? qsTrId('id_please_enable_camera') : qsTrId('id_camera_problem')
        }
    }

    CaptureSession {
        camera: Camera {
            id: camera
            cameraDevice: camera_selector.cameraDevice
            active: self.cameraAvailable && permission.status === Qt.Granted
        }
        videoOutput: video_output
    }

    VideoOutput {
        id: video_output
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
        visible: self.cameraAvailable && camera.active
    }

    Item {
        anchors.centerIn: self
        visible: self.cameraAvailable && camera.active
        scale: Math.max(self.width / video_output.sourceRect.width, self.height / video_output.sourceRect.height)
        width: video_output.sourceRect.width
        height: video_output.sourceRect.height

        Repeater {
            model: self.barcodeOverlays
            delegate: Shape {
                ShapePath {
                    fillColor: Qt.alpha('#00BCFF', 0.25)
                    startX: modelData[0].x
                    startY: modelData[0].y
                    strokeColor: Qt.alpha('#00BCFF', 0.75)
                    strokeWidth: 10
                    joinStyle: ShapePath.RoundJoin
                    PathLine {
                        x: modelData[1].x
                        y: modelData[1].y
                    }
                    PathLine {
                        x: modelData[2].x
                        y: modelData[2].y
                    }
                    PathLine {
                        x: modelData[3].x
                        y: modelData[3].y
                    }
                    PathLine {
                        x: modelData[0].x
                        y: modelData[0].y
                    }
                }
            }
        }
    }

    Timer {
        id: overlay_timer
        interval: 200
        onTriggered: self.barcodeOverlays = []
    }

    BarcodeReader {
        id: detector
        formats: [ZXing.QRCode]
        tryHarder: true
        tryDownscale: true
        videoSink: video_output.videoSink
        onFoundBarcodes: (barcodes) => {
            self.barcodeOverlays = barcodes.map((barcode) => [
                { x: barcode.position.topLeft.x, y: barcode.position.topLeft.y },
                { x: barcode.position.topRight.x, y: barcode.position.topRight.y },
                { x: barcode.position.bottomRight.x, y: barcode.position.bottomRight.y },
                { x: barcode.position.bottomLeft.x, y: barcode.position.bottomLeft.y },
            ])
            for (const barcode of barcodes)
                controller.process(barcode.text)
            overlay_timer.restart()
        }
    }
    BCURController {
        id: controller
        context: self.context
        onResultDecoded: (result) => self.bcurScanned(result)
        onDataDiscarded: (data) => self.codeScanned(data)
    }

    TProgressBar {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 20
        from: 0
        opacity: 0.6
        to: 100
        visible: self.cameraAvailable && controller.progress > 0
        value: controller.progress
    }

    CameraSelector {
        id: camera_selector
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 16
        visible: self.cameraAvailable && camera.active
    }

    component CameraSelector: AbstractButton {
        property var cameraDevice: media_devices.defaultVideoInput
        id: self
        padding: 4
        enabled: media_devices.videoInputs.length > 1
        background: Rectangle {
            color: '#000000'
            radius: height / 2
            opacity: 0.5
        }
        contentItem: RowLayout {
            spacing: 4
            Label {
                text: self.cameraDevice.description
                font.pixelSize: 12
                color: '#FFFFFF'
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/caret-down-white.svg'
                visible: self.enabled
            }
        }
        MediaDevices {
            id: media_devices
            onVideoInputsChanged: self.cameraDevice = media_devices.defaultVideoInput
        }
        GMenu {
            id: devices_menu
            x: self.width * 0.5 - devices_menu.width * 0.8
            y: -devices_menu.height - 8
            pointerX: 0.8
            pointerY: 1
            Repeater {
                model: media_devices.videoInputs
                delegate: GMenu.Item {
                    required property var modelData
                    id: item
                    hideIcon: true
                    text: modelData.description
                    onClicked: {
                        devices_menu.close()
                        self.cameraDevice = item.modelData
                    }
                }
            }
        }
        onClicked: devices_menu.open()
    }
}
