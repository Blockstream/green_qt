import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13
import '..'

WizardPage {
    property alias valid: accept_checkbox.checked

    title: qsTr('TERM OF SERVICE')
    activeFocusOnTab: false

    CheckBox {
        id: accept_checkbox
        anchors.centerIn: parent
        focus: true
        text: qsTr("I ACCEPT!")
    }
}
