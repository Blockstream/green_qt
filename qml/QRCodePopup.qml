import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import QtQuick.Shapes

Popup {
    required property string text

    id: self
    background: MouseArea {
        hoverEnabled: true
    }
    x: parent.width / 2 - width / 2
    y: -height
    contentItem: Loader {
        active: self.visible
        sourceComponent: Item {
            implicitWidth: 200
            implicitHeight: 208
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
                PopupBalloon {
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
                    anchors.bottomMargin: 8
                    source: `image://zxing/${encodeURI(self.text || '')}`
                }
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Shape {
                        width: qrcode.width
                        height: qrcode.height
                        PopupBalloon {
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
                PopupBalloon {
                    strokeColor: '#00BCFF'
                    strokeWidth: 1
                    fillColor: 'transparent'
                }
            }
        }
    }
}
