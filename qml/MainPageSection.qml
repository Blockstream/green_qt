import QtQuick 2.13
import QtQuick.Controls 2.13

Page {
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
