import QtQuick 2.13
import QtQuick.Controls 2.13

Item {
    Image {
        id: logo
        anchors.centerIn: parent
        source: 'assets/svg/logo_big.svg'
        opacity: 0.2
    }

    FlatButton {
        icon.source: 'assets/svg/add_wallet.svg'
        icon.width: 16
        icon.height: 16
        text: qsTr('id_create_new_wallet')
        anchors.horizontalCenter: logo.horizontalCenter
        anchors.top: logo.bottom
        anchors.margins: 16
        action: create_wallet_action
    }
}
