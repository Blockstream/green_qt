import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

MnemonicWarningsPage {
    signal completed()
    required property Context context
    id: self
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    onAccepted: self.StackView.view.push(mnemonic_backup_page)

    Component {
        id: mnemonic_backup_page
        MnemonicBackupPage {
            columns: 2
            context: self.context
            rightItem: CloseButton {
                onClicked: self.closeClicked()
            }
            onSelected: (mnemonic) => self.StackView.view.push(mnemonic_check_page, { mnemonic })
        }
    }

    Component {
        id: mnemonic_check_page
        MnemonicCheckPage {
            rightItem: CloseButton {
                onClicked: self.closeClicked()
            }
            onChecked: {
                Settings.unregisterEvent({ walletId: self.context.xpubHashId, status: 'pending', type: 'wallet_backup' })
                context.checkAndAddBackupWarningNotification();
                self.StackView.view.push(backup_complete_page)
            }
        }
    }

    Component {
        id: backup_complete_page
        StackViewPage {
            leftItem: null
            title: qsTrId('id_completed')
            rightItem: CloseButton {
                onClicked: self.closeClicked()
            }
            contentItem: ColumnLayout {
                spacing: 20
                VSpacer {}
                Label {
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    horizontalAlignment: Label.AlignHCenter
                    font.pixelSize: 22
                    font.weight: 600
                    text: qsTrId('id_completed')
                    wrapMode: Label.Wrap
                }
                Label {
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    Layout.maximumWidth: 400
                    horizontalAlignment: Label.AlignHCenter
                    font.pixelSize: 14
                    opacity: 0.6
                    text: 'You have successfully verified your recovery phrase backup.'
                    wrapMode: Label.Wrap
                }
                PrimaryButton {
                    Layout.alignment: Qt.AlignCenter
                    Layout.minimumWidth: 250
                    text: qsTrId('id_done')
                    onClicked: self.completed()
                }
                VSpacer {}
            }
        }
    }
}
