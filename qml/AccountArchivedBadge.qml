import Blockstream.Green
import QtQuick
import QtQuick.Controls

Label {
    required property Account account
    id: self
    font.pixelSize: 10
    font.capitalization: Font.AllUppercase
    font.styleName: 'Medium'
    leftPadding: 8
    rightPadding: 26
    topPadding: 4
    bottomPadding: 4
    color: 'white'
    background: Rectangle {
        color: Qt.alpha(constants.c300, 0.5)
        radius: 4
        Image {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 8
            height: 10
            width: 10
            fillMode: Image.PreserveAspectFit
            source: 'qrc:/svg/x.svg'
        }
    }
    text: qsTrId('id_archived')
    visible: self.account?.hidden ?? false
    TapHandler {
        onTapped: controller.setAccountHidden(self.account, false)
    }
}
