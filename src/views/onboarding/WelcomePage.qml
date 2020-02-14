import QtQuick 2.13
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import '..'

ColumnLayout {
    property bool agreeWithTermsOfService: checkbox.checked

    anchors.fill: parent

    Image {
        fillMode: Image.PreserveAspectFit
        source: '../../assets/svg/onboarding_illustration.svg'
        horizontalAlignment: Qt.AlignHCenter
        verticalAlignment: Qt.AlignVCenter
        Layout.alignment: Qt.AlignHCenter
        Layout.fillHeight: true
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        CheckBox {
            id: checkbox
            focus: true
            text: qsTrId('id_i_agree_to_the')
        }
        Label {
            text: '<a href="https://blockstream.com/green/terms/">' + qsTrId('id_terms_of_service') + '</a>'
            onLinkActivated: Qt.openUrlExternally(link)
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
            }
        }
    }
}
