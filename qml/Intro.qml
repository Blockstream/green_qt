import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

StackLayout {
    property Item toolbar: TextField {
        id: search_field
        placeholderText: qsTrId('id_search')
        Layout.minimumWidth: 256
    }

    currentIndex: WalletManager.wallets.length > 0 ? 0 : 1

    Component {
        id: remove_wallet_dialog
        AbstractDialog {
            title: qsTrId('id_remove_wallet')
            property Wallet wallet
            anchors.centerIn: parent
            modal: true
            onAccepted: {
                WalletManager.removeWallet(wallet)
            }
            ColumnLayout {
                spacing: 8
                Label {
                    text: qsTrId('id_backup_your_mnemonic_before')
                }
                SectionLabel {
                    text: qsTrId('id_name')
                }
                Label {
                    text: wallet.name
                }
                SectionLabel {
                    text: qsTrId('id_network')
                }
                Row {
                    Image {
                        sourceSize.width: 16
                        sourceSize.height: 16
                        source: icons[wallet.network.id]
                    }
                    Label {
                        text: wallet.network.name
                    }
                }

                SectionLabel {
                    text: qsTrId('id_confirm_action')
                }
                TextField {
                    Layout.minimumWidth: 300
                    id: confirm_field
                    placeholderText: qsTrId('id_confirm_by_typing_the_wallet')
                }
            }
            footer: DialogButtonBox {
                    Button {
                    text: qsTrId('id_remove')
                    DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                    enabled: confirm_field.text === wallet.name
                }
            }
        }
    }

    ListView {
        id: wallet_list_view
        clip: true
        model: WalletListModel {
            filterRegExp: new RegExp(search_field.text.trim(), 'i')
        }
        section.property: 'wallet.networkName'
        section.criteria: ViewSection.FullString
        section.delegate: SectionLabel {
            padding: 16
            text: section
        }

        delegate: ItemDelegate {
            id: delegate
            width: wallet_list_view.width
            icon.source: icons[wallet.network.id]
            icon.color: 'transparent'
            text: wallet.name
            property bool valid: wallet.loginAttemptsRemaining > 0
            onClicked: if (valid) switchToWallet(wallet)
            highlighted: wallet.connection !== Wallet.Disconnected
            Row {
                visible: !valid || parent.hovered
                anchors.right: parent.right
                anchors.rightMargin: 32
                Menu {
                    id: wallet_menu
                    MenuItem {
                        enabled: wallet.connection !== Wallet.Disconnected
                        text: qsTrId('id_log_out')
                        onTriggered: wallet.disconnect()
                    }
                    MenuItem {
                        enabled: wallet.connection === Wallet.Disconnected
                        text: qsTrId('id_remove_wallet')
                        onClicked: remove_wallet_dialog.createObject(window, { wallet }).open()
                    }
                }
                Label {
                    visible: wallet.loginAttemptsRemaining === 0
                    anchors.verticalCenter: parent.verticalCenter
                    text: '\u26A0'
                    font.pixelSize: 18
                    ToolTip.text: qsTrId('id_no_attempts_remaining')
                    ToolTip.visible: !valid && delegate.hovered
                    ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                }
                ToolButton {
                    text: '\u22EF'
                    onClicked: wallet_menu.open()
                }
            }
        }

        Layout.fillWidth: true
        Layout.fillHeight: true

        ScrollBar.vertical: ScrollBar { }

        ScrollShadow {}
    }

    Item {
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 16
            Image {
                Layout.alignment: Qt.AlignHCenter
                source: 'qrc:/svg/logo_big.svg'
                sourceSize.height: 64
            }
            Button {
                Layout.fillWidth: true
                action: create_wallet_action
            }
            Button {
                Layout.fillWidth: true
                action: restore_wallet_action
            }
        }
    }
}
