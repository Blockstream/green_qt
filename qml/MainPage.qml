import QtQuick 2.13
import QtQuick.Controls 2.13

Page {
    background: Rectangle {
        color: constants.c800
    }
    leftPadding: 32
    rightPadding: 32
    component Header: Pane {
        leftPadding: 32
        rightPadding: 32
        background: Item {}
    }
    component Section: Page {
        id: section
        padding: 16
        header: SectionLabel {
            topPadding: 16
            leftPadding: 16
            text: title
        }
        background: Item {
            Rectangle {
                color: constants.c600
                implicitHeight: 1
                width: parent.width
                anchors.bottom: parent.bottom
            }
        }
    }
}
