import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    signal singlesigWallet
    signal multisigWallet
    id: self
    padding: 60
    contentItem: ColumnLayout {
        VSpacer {
        }
        ColumnLayout {
            Layout.alignment: Qt.AlignCenter
            Layout.fillHeight: false
            Layout.fillWidth: false
            Layout.maximumWidth: 400
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                font.family: 'SF Compact Display'
                font.pixelSize: 26
                font.weight: 600
                horizontalAlignment: Label.AlignHCenter
                text: qsTrId('id_select_watchonly_type')
                wrapMode: Label.WordWrap
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.bottomMargin: 20
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                font.family: 'SF Compact Display'
                font.pixelSize: 14
                font.weight: 400
                horizontalAlignment: Label.AlignHCenter
                opacity: 0.4
                text: qsTrId('id_choose_the_security_policy_that')
                wrapMode: Label.Wrap
            }
            Option {
                Layout.fillWidth: true
                enabled: false
                icon.source: 'qrc:/svg2/singlesig.svg'
                type: qsTrId('id_singlesig') + '/' + qsTrId('id_legacy_segwit')
                text: qsTrId('id_standard')
                description: 'Enter the xPub or descriptor of the singlesig account you want watch-only access for.'
                onClicked: self.singlesigWallet()
            }
            Option {
                Layout.fillWidth: true
                icon.source: 'qrc:/svg2/multisig.svg'
                type: qsTrId('id_multisig') + ' / ' + qsTrId('id_2of2')
                text: qsTrId('id_2fa_protected')
                description: 'Log in to your 2FA Protected accounts with a username and password.'
                onClicked: self.multisigWallet()
            }
        }
        VSpacer {
        }
    }

    component Option: AbstractButton {
        required property string type
        required property string description

        id: self
        padding: 20
        background: Rectangle {
            color: '#222226'
            radius: 5
            Rectangle {
                border.width: 2
                border.color: '#00B45A'
                color: 'transparent'
                radius: 9
                anchors.fill: parent
                anchors.margins: -4
                visible: self.visualFocus
            }
        }
        contentItem: RowLayout {
            spacing: 20
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                RowLayout {
                    spacing: 4
                    Image {
                        Layout.alignment: Qt.AlignCenter
                        opacity: self.enabled ? 1 : 0.2
                        source: self.icon.source
                    }
                    Label {
                        Layout.alignment: Qt.AlignCenter
                        font.family: 'SF Compact Display'
                        font.pixelSize: 10
                        font.capitalization: Font.AllUppercase
                        font.weight: 400
                        topPadding: 4
                        bottomPadding: 4
                        leftPadding: 8
                        rightPadding: 8
                        text: self.type
                    }
                }
                Label {
                    font.family: 'SF Compact Display'
                    font.pixelSize: 16
                    font.weight: 600
                    text: self.text
                }
                Label {
                    Layout.fillWidth: true
                    Layout.topMargin: 10
                    font.family: 'SF Compact Display'
                    font.pixelSize: 12
                    font.weight: 400
                    opacity: 0.6
                    text: self.description
                    wrapMode: Label.WordWrap
                }
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                opacity: self.enabled ? 1 : 0.2
                source: 'qrc:/svg2/next_arrow.svg'
            }
        }
    }
}
