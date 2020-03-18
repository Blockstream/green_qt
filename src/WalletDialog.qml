import QtQuick 2.14
import QtQuick.Controls 2.14

Dialog {
    Connections {
        target: wallet
        onConnectionChanged: reject()
    }
}
