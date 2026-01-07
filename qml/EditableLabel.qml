import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

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
        border.color: self.activeFocus ? '#00BCFF' : '#FFFFFF'
        radius: 4
        visible: !self.readOnly
        opacity: (self.activeFocus ? 0.4 : 0) + (self.hovered ? 0.1 : 0)
        Behavior on opacity {
            SequentialAnimation {
                PauseAnimation {
                    duration: 200
                }
                SmoothedAnimation {
                    velocity: 2
                }
            }
        }
    }
    bottomPadding: topPadding
    cursorPosition: 0
    selectByMouse: activeFocus
    maximumLength: 50
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
