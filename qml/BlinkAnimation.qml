import QtQuick 2.13

SequentialAnimation {
    loops: Animation.Infinite
    alwaysRunToEnd: true
    NumberAnimation { from: 1.0; to: 0.25; duration: 500 }
    NumberAnimation { from: 0.25; to: 1.0; duration: 500 }
}
