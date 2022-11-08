import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

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
            return dynamicScenePosition(self, -8, -8)
        }
        id: popup
        x: scenePosition.x
        y: scenePosition.y
        width: self.width + 16 + 8 + 16
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
            spacing: 8
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
