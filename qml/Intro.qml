import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

Item {
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 16
        Image {
            Layout.alignment: Qt.AlignHCenter
            source: 'qrc:/svg/green_logo.svg'
            sourceSize.height: 64
        }
        Button {
            Layout.fillWidth: true
            flat: true
            action: create_wallet_action
        }
        Button {
            Layout.fillWidth: true
            flat: true
            action: restore_wallet_action
        }
    }
}
