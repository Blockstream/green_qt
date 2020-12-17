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
        Label {
            property real device_count: device_list_model.rowCount
            Behavior on device_count { SmoothedAnimation { velocity: 0.5 } }
            opacity: device_count > 0 ? 0 : 1
            Behavior on opacity { OpacityAnimator {} }
            text: qsTrId('id_connect_your_ledger_to_use_it')
            padding: 16
            background: Rectangle {
                color: Qt.lighter('#141a21', 1.5)
                border.width: 1
                border.color: Qt.lighter('#141a21', 2)
                radius: height / 2
            }
        }
    }
}
