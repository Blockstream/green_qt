import QtQuick 2.13
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.13

Page {
    topPadding: 8
    bottomPadding: 8
    leftPadding: 16
    rightPadding: 16
    header: SectionLabel {
        text: title
        topPadding: 8
        bottomPadding: 8
        leftPadding: 16
        rightPadding: 16
    }
    background: Rectangle {
        radius: 8
        color: constants.c700
    }
    Layout.fillWidth: true
}
