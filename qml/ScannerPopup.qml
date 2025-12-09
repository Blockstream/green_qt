import Blockstream.Green
import Blockstream.Green.Core
import QtCore
import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import QtQuick.Shapes

Popup {
    signal codeScanned(string code)
    signal bcurScanned(var result)
    property bool scanned: false
    readonly property bool available: window.hasVideoInput && permission.status !== Qt.Denied
    function requestPermissionAndOpen() {
        if (permission.status === Qt.Granted) {
            self.open()
        } else if (permission.status === Qt.Undetermined) {
            permission.request()
        }
    }

    CameraPermission {
        id: permission
        onStatusChanged: self.requestPermissionAndOpen()
    }
    onOpened: self.scanned = false
    id: self
    background: null
    x: parent.width / 2 - width / 2
    y: -height + parent.height / 2
    contentItem: Loader {
        active: self.visible
        sourceComponent: Item {
            implicitWidth: 300
            implicitHeight: 200
            DropShadow {
                opacity: 0.5
                verticalOffset: 8
                radius: 32
                samples: 16
                source: bg
                anchors.fill: parent
            }
            Shape {
                id: bg
                anchors.fill: parent
                layer.samples: 4
                PopupBalloon {
                    strokeWidth: 0
                    fillColor: constants.c700
                }
            }
            ScannerView {
                id: scanner_view
                anchors.fill: parent
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Shape {
                        width: scanner_view.width
                        height: scanner_view.height
                        PopupBalloon {
                            strokeWidth: 1
                            strokeColor: 'transparent'
                            fillColor: 'white'
                        }
                    }
                }
                onCodeScanned: (code) => {
                    if (!self.scanned) {
                        self.scanned = true
                        self.codeScanned(code)
                        self.close()
                    }
                }
                onBcurScanned: (result) => {
                    if (!self.scanned) {
                        self.scanned = true
                        self.bcurScanned(result)
                        self.close()
                    }
                }
            }
            Shape {
                anchors.fill: parent
                layer.samples: 4
                PopupBalloon {
                    strokeColor: '#343842'
                    strokeWidth: 1
                    fillColor: 'transparent'
                }
            }
            CloseButton {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 20
                onClicked: self.close()
            }
        }
    }
}
