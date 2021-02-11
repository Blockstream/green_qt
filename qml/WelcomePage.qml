import QtQuick 2.13
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

ColumnLayout {
    property string title: qsTrId('id_welcome_to') + ' ' + qsTrId('Blockstream Green')
    property list<Action> actions: [
        Action {
            text: qsTrId('id_continue')
            enabled: agreeWithTermsOfService
            onTriggered: next()
        }
    ]
    property bool agreeWithTermsOfService: checkbox.checked
    signal next()

    Image {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.alignment: Qt.AlignCenter
        fillMode: Image.PreserveAspectFit
        source: 'qrc:/svg/onboarding_illustration.svg'
    }
    RowLayout {
        Layout.fillWidth: false
        Layout.fillHeight: false
        Layout.alignment: Qt.AlignCenter
        CheckBox {
            id: checkbox
            focus: true
        }
        Label {
            text: qsTrId('id_i_agree_to_the') + ' ' + '<a href="https://blockstream.com/green/terms/">' + qsTrId('id_terms_of_service') + '</a>'
            onLinkActivated: Qt.openUrlExternally(link)
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
            }
        }
    }
    Item {
        Layout.fillHeight: true
        width: 1
    }
}
