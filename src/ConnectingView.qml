import Blockstream.Green 0.1
import QtQuick 2.0
import QtQuick.Controls 2.5

Column {
    spacing: 16

    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        font.pixelSize: 16
        opacity: wallet.events.tor !== undefined && wallet.events.tor.progress > 0 && wallet.events.tor.progress < 100 ? 1 : 0
        text: wallet.events.tor ? wallet.events.tor.summary : ''

        Behavior on opacity {
            SmoothedAnimation { }
        }
    }

    ProgressBar {
        property var tor: wallet.events.tor

        anchors.horizontalCenter: parent.horizontalCenter
        from: 0
        indeterminate: !(tor && tor.progress >= 0 && tor.progress < 100)
        to: 100
        value: wallet.events.tor ? wallet.events.tor.progress : 0

        Behavior on value {
            SmoothedAnimation {  }
        }
    }

    FlatButton {
        anchors.horizontalCenter: parent.horizontalCenter
        text: qsTr('id_cancel')
        onClicked: wallet.disconnect()
    }

}
