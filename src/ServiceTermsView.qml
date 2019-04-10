import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

FocusScope {
    property alias accepted: accept_checkbox.checked

    CheckBox {
        id: accept_checkbox
        anchors.centerIn: parent
        focus: true
        text: qsTr("I ACCEPT!")
    }
}
