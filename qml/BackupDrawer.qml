import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

WalletDrawer {
    id: self
    contentItem: GStackView {
        id: stack_view
        initialItem: MnemonicWarningsPage {
            rightItem: CloseButton {
                onClicked: self.close()
            }
            onAccepted: stack_view.push(mnemonic_backup_page)
        }
    }

    Component {
        id: mnemonic_backup_page
        MnemonicBackupPage {
            columns: 2
            mnemonic: self.context.mnemonic
            rightItem: CloseButton {
                onClicked: self.close()
            }
            onSelected: (mnemonic) => stack_view.push(mnemonic_check_page, { mnemonic })
        }
    }

    Component {
        id: mnemonic_check_page
        MnemonicCheckPage {
            onChecked: {
                Settings.unregisterEvent({ walletId: self.context.xpubHashId, status: 'pending', type: 'wallet_backup' })
                stack_view.replace(null, backup_complete_page, StackView.PushTransition)
            }
        }
    }

    Component {
        id: backup_complete_page
        StackViewPage {
            title: qsTrId('id_completed')
            rightItem: CloseButton {
                onClicked: self.close()
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
                    onClicked: {
                        self.close()
                    }
                }
                VSpacer {}
            }
        }
    }
}
