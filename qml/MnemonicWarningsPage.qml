import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    signal accepted

    id: self
    contentItem: ColumnLayout {
        VSpacer {
        }
        Pane {
            Layout.alignment: Qt.AlignCenter
            background: null
            contentItem: ColumnLayout {
                spacing: 0
                width: 325
                Label {
                    Layout.alignment: Qt.AlignCenter
                    Layout.bottomMargin: 20
                    font.family: 'SF Compact'
                    font.pixelSize: 24
                    font.weight: 600
                    horizontalAlignment: Label.AlignHCenter
                    text: qsTrId('id_before_you_backup')
                }
                InfoCard {
                    icon: 'qrc:/svg2/house.svg'
                    title: qsTrId('id_safe_environment')
                    description: qsTrId('id_make_sure_you_are_alone_and_no')
                }
                InfoCard {
                    icon: 'qrc:/svg2/warning.svg'
                    title: qsTrId('id_sensitive_information')
                    description: qsTrId('id_whomever_can_access_your')
                }
                InfoCard {
                    icon: 'qrc:/svg2/shield_check.svg'
                    title: qsTrId('id_safely_stored')
                    description: qsTrId('id_if_you_forget_it_or_lose_it')
                }
                PrimaryButton {
                    Layout.alignment: Qt.AlignCenter
                    Layout.minimumWidth: 325
                    Layout.topMargin: 40
                    text: qsTrId('id_show_recovery_phrase')
                    onClicked: self.accepted()
                }
                PrintButton {
                    Layout.alignment: Qt.AlignCenter
                    Layout.topMargin: 40
                    text: 'Print Backup Template'
                }
            }
        }
        VSpacer {
        }
    }
}
