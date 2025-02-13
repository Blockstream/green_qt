import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    signal timeout()
    id: self
    Timer {
        id: timer
        running: self.StackView.status === StackView.Active
        interval: 5000
        repeat: false
        onTriggered: self.timeout()
    }
    CompletedImage {
        Layout.alignment: Qt.AlignCenter
    }
    Label {
        Layout.alignment: Qt.AlignCenter
        Layout.bottomMargin: 20
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        Layout.topMargin: 20
        font.pixelSize: 22
        font.weight: 600
        horizontalAlignment: Label.AlignHCenter
        text: qsTrId('Jade is rebooting')
        wrapMode: Label.WordWrap
    }
    BusyIndicator {
        Layout.alignment: Qt.AlignCenter
    }
}
