import QtQuick 2.13
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

GPane {
    property bool agreeWithTermsOfService: checkbox.checked
    signal next()
    contentItem: ColumnLayout {
        spacing: 20
        VSpacer {
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: qsTrId('id_welcome_to') + ' ' + qsTrId('Blockstream Green')
            font.pixelSize: 18
        }
        Image {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignCenter
            fillMode: Image.PreserveAspectFit
            source: 'qrc:/svg/onboarding_illustration.svg'
            Layout.minimumHeight: 120
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
    }
}
