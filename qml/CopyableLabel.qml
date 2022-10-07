import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

Label {
    id: self
    property real delay: 500
    property string copyText: text
    signal copy
    HoverHandler {
        id: hover_handler
        onHoveredChanged: check_timer.stop()
    }
    Timer {
        id: check_timer
        interval: 1000
        repeat: false
    }
    Popup {
        readonly property point scenePosition: {
            hover_handler.hovered
            return dynamicScenePosition(self, -8, -8)
        }
        id: popup
        x: scenePosition.x
        y: scenePosition.y
        width: self.width + 16 + 8 + 16
        height: self.height + 16
        padding: 8
        opacity: 0
        visible: hover_handler.hovered || popup_hover_handler.hovered
        parent: Overlay.overlay
        contentItem: RowLayout {
            spacing: 8
            Label {
                font: self.font
                text: self.text
            }
            Image {
                source: check_timer.running ? 'qrc:/svg/check.svg' : 'qrc:/svg/copy.svg'
                mipmap: true
                smooth: true
                Layout.preferredHeight: 16
                Layout.preferredWidth: 16
            }
        }
        background: Rectangle {
            color: constants.c400
            border.width: 1
            border.color: constants.c200
            radius: 4
            HoverHandler {
                id: popup_hover_handler
            }
            TapHandler {
                onTapped: {
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
