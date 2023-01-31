import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    topPadding: 0
    bottomPadding: 0
    leftPadding: 0
    rightPadding: 0
    header: SectionLabel {
        text: title
        topPadding: 0
        bottomPadding: constants.p0
        leftPadding: 0
        rightPadding: 0
    }
    background: null
    Layout.fillWidth: true
}
