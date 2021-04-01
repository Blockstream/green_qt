import QtQuick 2.13
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

ColumnLayout {
    property list<Action> actions: [
        Action {
            text: qsTrId('id_continue')
            enabled: agreeWithTermsOfService
            onTriggered: next()
        }
    ]
    property bool agreeWithTermsOfService: checkbox.checked
    signal next()

    spacing: 20
    Label {
        Layout.alignment: Qt.AlignHCenter
        text: qsTrId('id_welcome_to') + ' ' + qsTrId('Blockstream Green')
        font.pixelSize: 20
    }
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
            textFormat: Text.RichText
            text: qsTrId('id_i_agree_to_the') + ' ' + link('https://blockstream.com/green/terms/', qsTrId('id_terms_of_service'))
            onLinkActivated: Qt.openUrlExternally(link)
            background: MouseArea {
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
