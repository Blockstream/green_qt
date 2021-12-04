import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

TextField {
    signal edited(string text, bool activeFocus)
    id: self
    color: 'white'
    focus: false
    readOnly: !self.enabled
    activeFocusOnPress: true
    autoScroll: activeFocus
    background: Rectangle {
        color: 'transparent'
        border.width: 1
        border.color: self.activeFocus ? constants.g400 : 'white'
        Behavior on border.color {
            ColorAnimation {
            }
        }
        radius: 4
        visible: !self.readOnly
        opacity: (self.activeFocus ? 0.4 : 0) + (self.hovered ? 0.1 : 0)
        Behavior on opacity {
            SequentialAnimation {
                PauseAnimation {
                    duration: 300
                }
                SmoothedAnimation {
                    velocity: 1
                }
            }
        }
    }
    bottomPadding: topPadding
    cursorPosition: 0
    selectByMouse: activeFocus
    onTextChanged: {
        self.edited(text, self.activeFocus)
        if (!self.activeFocus) self.ensureVisible(0)
    }
    onActiveFocusChanged: {
        self.edited(self.text, activeFocus)
        if (!activeFocus) self.ensureVisible(0)
    }
    ToolTip.text: self.text
    ToolTip.visible: contentWidth > availableWidth && hovered
    ToolTip.delay: 1000
}
