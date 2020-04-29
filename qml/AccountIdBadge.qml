import Blockstream.Green 0.1
import QtQuick 2.0
import QtQuick.Controls 2.5

Label {
    leftPadding: 8
    rightPadding: 32
    text: qsTrId('id_account_id') + '    ' + account.json.receiving_id
    ToolTip.text: qsTrId('id_provide_this_id_to_the_issuer')
    ToolTip.delay: 500
    ToolTip.visible: mouse_area.containsMouse
    MouseArea {
        id: mouse_area
        anchors.fill: parent
        anchors.margins: -16
        hoverEnabled: true
        onClicked: {
            Clipboard.copy(account.json.receiving_id);
            ToolTip.show(qsTrId('id_copied_to_clipboard'), 1000);
        }
    }
    property real factor: mouse_area ? 1.3 : 1.5
    Rectangle {
        anchors.fill: parent
        anchors.margins: -8
        radius: height/2
        z: -1
        color: Qt.lighter('#141a21', factor + 0.4)
        clip: true
        Rectangle {
            radius: height/2
            height: parent.height
            width: height
            color: Qt.lighter('#141a21', factor)
        }
        Rectangle {
            x: height/2
            height: parent.height
            width: 88-height/2
            color: Qt.lighter('#141a21', factor)
        }
    }
    Image {
        source: '/svg/copy.svg'
        sourceSize.width: 12
        sourceSize.height: 12
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
    }
}
