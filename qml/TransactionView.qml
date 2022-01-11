import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

WalletDialog {
    id: self
    required property Transaction transaction
    readonly property Network network: transaction.account.wallet.network
    property int confirmations: transactionConfirmations(transaction)

    wallet: transaction.account.wallet
    title: qsTrId('id_transaction_details') + ' - ' + tx_direction(transaction.data.type)

    function tx_direction(type) {
        switch (type) {
            case 'incoming':
                return qsTrId('id_incoming')
            case 'outgoing':
                return qsTrId('id_outgoing')
            case 'redeposit':
                return qsTrId('id_redeposited')
        }
    }

    Component {
        id: liquid_amount_delegate
        GPane {
            property TransactionAmount amount: modelData
            Layout.fillWidth: true
            background: Rectangle {
                color: constants.c600
                radius: 4
            }
            contentItem: RowLayout {
            spacing: 16
                AssetIcon {
                    asset: amount.asset
                }
                ColumnLayout {
                    Label {
                        Layout.fillWidth: true
                        text: amount.asset.name
                        font.pixelSize: 14
                        elide: Label.ElideRight
                    }

                    Label {
                        visible: 'entity' in amount.asset.data
                        Layout.fillWidth: true
                        opacity: 0.5
                        text: amount.asset.data.entity ? amount.asset.data.entity.domain : ''
                        elide: Label.ElideRight
                    }
                }
                HSpacer {
                }
                Label {
                    text: {
                        wallet.displayUnit
                        return amount.formatAmount(true)
                    }
                    color: amount.transaction.data.type === 'incoming' ? '#00b45a' : 'white'
                    font.pixelSize: 16
                    font.styleName: 'Medium'
                }
            }
        }
    }

    Component {
        id: bitcoin_amount_delegate
        GPane {
            property TransactionAmount amount: modelData
            Layout.fillWidth: true
            background: Rectangle {
                color: constants.c600
                radius: 4
            }
            contentItem: ColumnLayout {
                spacing: constants.s0
                SectionLabel {
                    visible: transaction.data.type === 'outgoing'
                    text: qsTrId('id_recipient')
                }
                Label {
                    visible: transaction.data.type === 'outgoing'
                    text: transaction.data.addressees[0]
                }
                RowLayout {
                    spacing: constants.s0
                    Image {
                        fillMode: Image.PreserveAspectFit
                        sourceSize.height: 24
                        sourceSize.width: 24
                        source: icons[network.key]
                    }
                    Label {
                        Layout.fillWidth: true
                        text: wallet.displayUnit
                        font.pixelSize: 14
                        elide: Label.ElideRight
                    }
                    HSpacer {
                    }
                    Label {
                        text: {
                            wallet.displayUnit
                            return amount.formatAmount(wallet.settings.unit)
                        }
                        color: amount.transaction.data.type === 'incoming' ? '#00b45a' : 'white'
                        font.pixelSize: 16
                        font.styleName: 'Medium'
                    }
                }
            }
        }
    }

    contentItem: GFlickable {
        id: flickable
        clip: true
        implicitHeight: layout.implicitHeight
        implicitWidth: layout.implicitWidth
        contentHeight: layout.height
        MouseArea {
            anchors.fill: layout
            onClicked: flickable.forceActiveFocus()
        }

        ColumnLayout {
            id: layout
            width: flickable.availableWidth
            spacing: constants.s1

            GPane {
                visible: !network.liquid && (transaction.data.type === 'redeposit' || transaction.data.type === 'outgoing')
                enabled: confirmations === 0
                Layout.fillWidth: true
                background: Rectangle {
                    radius: 4
                    color: constants.c500
                }
                contentItem: RowLayout {
                    Label {
                        text: confirmations === 0 ? qsTrId('Until the first confirmation, you can still speed up with a bigger fee.') : qsTrId('You can no longer speed up the transaction.')
                        font.pixelSize: 12
                    }
                    HSpacer {
                    }
                    GButton {
                        highlighted: confirmations === 0
                        text: qsTrId('Speed up')
                        font.pixelSize: 10
                        enabled: transaction.data.can_rbf
                        onClicked: {
                            bump_fee_dialog.createObject(window, { transaction }).open()
                            self.accept()
                        }
                    }
                }
            }

            Repeater {
                model: transaction.amounts
                delegate: network.liquid ? liquid_amount_delegate : bitcoin_amount_delegate
            }

            GPane {
                Layout.fillWidth: true
                background: null
                contentItem: RowLayout {
                    spacing: 16
                    Label {
                        text: qsTrId('id_fee')
                    }
                    HSpacer {
                    }
                    ColumnLayout {
                        Label {
                            Layout.alignment: Qt.AlignRight
                            text: formatAmount(transaction.data.fee)
                        }
                        Label {
                            Layout.alignment: Qt.AlignRight
                            text: `≈ ` + formatFiat(transaction.data.fee)
                        }
                        Label {
                            Layout.alignment: Qt.AlignRight
                            text: `(${transaction.data.fee_rate / 1000} satoshi/vbyte)`
                        }
                    }
                }
            }

            GPane {
                Layout.fillWidth: true
                background: Rectangle {
                    border.color: constants.c500
                    border.width: 1
                    color: 'transparent'
                    radius: 4
                }

                contentItem: RowLayout {
                    ColumnLayout {
                        Layout.fillWidth: false
                        spacing: constants.s1
                        CopyableLabel {
                            font.pixelSize: 12
                            text: formatTransactionTimestamp(transaction.data)
                        }
                        TransactionStatusBadge {
                            transaction: self.transaction
                            confirmations: self.confirmations
                            showConfirmations: false
                        }
                    }
                    HSpacer {
                    }
                    TransactionProgress {
                        Layout.maximumWidth: 64
                        Layout.preferredWidth:  64
                        Layout.preferredHeight: 64
                        max: network.liquid ? 2 : 6
                        current: confirmations
                    }
                }
            }

            ColumnLayout {
                spacing: constants.p0

                SectionLabel {
                    text: qsTrId('id_transaction_id')
                }

                CopyableLabel {
                    text: transaction.data.txhash
                }
            }

            ColumnLayout {
                spacing: constants.p0

                SectionLabel {
                    text: qsTrId('id_account_name')
                }

                CopyableLabel {
                    text: transaction.account.name
                }
            }

            ColumnLayout {
                spacing: constants.p0

                SectionLabel {
                    visible: !wallet.watchOnly
                    text: qsTrId('id_my_notes')
                }

                EditableLabel {
                    id: memo_edit
                    visible: !wallet.watchOnly
                    leftPadding: constants.p0
                    rightPadding: constants.p0
                    Layout.fillWidth: true
                    placeholderText: qsTrId('id_add_a_note_only_you_can_see_it')
                    text: transaction.memo
                    selectByMouse: true
                    wrapMode: TextEdit.Wrap
                    onEditingFinished: transaction.updateMemo(memo_edit.text)
                    onTextChanged: {
                        if (text.length > 1024) {
                            memo_edit.text = text.slice(0, 1024);
                        }
                    }
                }
            }

            HSpacer { }
        }
    }
    footer: DialogFooter {
        ToolButton {
            flat: true
            icon.width: 16
            icon.height: 16
            icon.source: 'qrc:/svg/qr.svg'
            onClicked: qrcode_popup.open()
            QRCodePopup {
                id: qrcode_popup
                text: network.liquid ? transaction.unblindedLink() : transaction.link()
            }
        }
        HSpacer {
        }
        GButton {
            text: qsTrId('id_view_in_explorer')
            onClicked: transaction.openInExplorer()
        }
        GButton {
            text: qsTrId('id_copy_unblinded_link')
            visible: network.liquid
            onClicked: {
                Clipboard.copy(transaction.unblindedLink())
                ToolTip.show(qsTrId('id_copied_to_clipboard'), 1000)
            }
        }
        GButton {
            text: qsTrId('id_copy_unblinding_data')
            visible: network.liquid
            onClicked: copyUnblindingData(this, transaction.data)
        }
    }

    Component {
        id: bump_fee_dialog
        BumpFeeDialog {
        }
    }
}
