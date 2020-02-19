import QtQuick 2.13
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import '..'

Column {
    property string title: qsTrId('id_welcome_to') + ' ' + qsTr('Blockstream Green')
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
        fillMode: Image.PreserveAspectFit
        source: '../../assets/svg/onboarding_illustration.svg'
        horizontalAlignment: Qt.AlignHCenter
        verticalAlignment: Qt.AlignVCenter
        opacity: anim(500, 500, 0, 1)
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: -checkbox.width * (1 - checkbox.opacity)
        CheckBox {
            id: checkbox
            focus: true
            opacity: anim(1000, 500, 0, 1)
            anchors.verticalCenter: parent.verticalCenter
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: qsTrId('id_i_agree_to_the') + ' ' + '<a href="https://blockstream.com/green/terms/">' + qsTrId('id_terms_of_service') + '</a>'
            onLinkActivated: Qt.openUrlExternally(link)
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
            }
        }
    }
}
