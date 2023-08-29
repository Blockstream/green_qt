import QtQuick
import QtQuick.Controls

StackView {
    property real duration: 200
    property real offset: 50
    property int easing: Easing.OutCubic
    id: self
    pushEnter: Transition {
        SequentialAnimation {
            ParallelAnimation {
                PropertyAction { property: "x"; value: self.offset }
                PropertyAction { property: "opacity"; value: 0 }
            }
            PauseAnimation {
                duration: self.duration
            }
            ParallelAnimation {
                NumberAnimation { property: "x"; to: 0; duration: self.duration; easing.type: self.easing }
                NumberAnimation { property: "opacity"; to: 1.0; duration: self.duration; easing.type: self.easing }
            }
        }
    }
    pushExit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "x"; from: 0; to: -self.offset; duration: self.duration; easing.type: self.easing }
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: self.duration; easing.type: self.easing }
        }
    }
    popEnter: Transition {
        SequentialAnimation {
            ParallelAnimation {
                PropertyAction { property: "x"; value: -self.offset }
                PropertyAction { property: "opacity"; value: 0 }
            }
            PauseAnimation {
                duration: self.duration
            }
            ParallelAnimation {
                NumberAnimation { property: "x"; to: 0; duration: self.duration; easing.type: self.easing }
                NumberAnimation { property: "opacity"; to: 1.0; duration: self.duration; easing.type: self.easing }
            }
        }
    }
    popExit: Transition {
        ParallelAnimation {
            NumberAnimation { property: "x"; from: 0; to: self.offset; duration: self.duration; easing.type: self.easing }
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: self.duration; easing.type: self.easing }
        }
    }

    component View: GPane {
        background: null
    }
}
