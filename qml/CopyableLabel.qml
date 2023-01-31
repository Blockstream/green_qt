import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

Label {
    id: self
    property real delay: 500
    property string copyText: text
    signal copy
    MouseArea {
        id: hover_handler
        anchors.fill: parent
        hoverEnabled: true
        onContainsMouseChanged: check_timer.stop()
    }
    Timer {
        id: check_timer
        interval: 1000
        repeat: false
    }
    Popup {
        readonly property point scenePosition: {
            hover_handler.containsMouse
            return UtilJS.dynamicScenePosition(self, -8, -8)
        }
        id: popup
        x: scenePosition.x
        y: scenePosition.y
        width: self.width + popup.opacity * 16 + 16 + 16
        height: self.height + 16
        padding: 8
        opacity: 0
        dim: true
        visible: hover_handler.containsMouse || popup_hover_handler.containsMouse
        parent: Overlay.overlay
        Overlay.modeless: Rectangle {
            color: Qt.rgba(0, 0, 0, popup.opacity * 0.4)
        }
        contentItem: RowLayout {
            spacing: 16
            Label {
                Layout.maximumWidth: self.width
                padding: self.padding
                font: self.font
                text: self.text
                wrapMode: self.wrapMode
                elide: self.elide
                horizontalAlignment: self.horizontalAlignment
                verticalAlignment: self.verticalAlignment
            }
            Item {
                Layout.preferredHeight: 16
                Layout.preferredWidth: 16
                Layout.maximumWidth: popup.opacity * 16
                Image {
                    anchors.right: parent.right
                    width: 16
                    height: 16
                    anchors.verticalCenter: parent.verticalCenter
                    source: check_timer.running ? 'qrc:/svg/check.svg' : 'qrc:/svg/copy.svg'
                    mipmap: true
                    smooth: true
                    opacity: popup.opacity
                }
            }
        }
        background: Rectangle {
            color: constants.c400
            border.width: 1
            border.color: constants.c200
            radius: 4
            MouseArea {
                id: popup_hover_handler
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    Clipboard.copy(self.copyText)
                    check_timer.start()
                    self.copy()
                }
            }
        }
        enter: Transition {
            SequentialAnimation {
                PauseAnimation { duration: self.delay }
                NumberAnimation { property: 'opacity'; to: 1 }
            }
        }
        exit: Transition {
            NumberAnimation { property: 'opacity'; to: 0 }
        }
    }
}
