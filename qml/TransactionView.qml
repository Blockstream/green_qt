import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

WalletDialog {
    required property Transaction transaction
    property int confirmations: transactionConfirmations(transaction)

    id: self
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
        RowLayout {
            property TransactionAmount amount: modelData

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

            Label {
                text: {
                    wallet.displayUnit
                    return amount.formatAmount(wallet.settings.unit)
                }
            }
        }
    }

    Component {
        id: bitcoin_amount_delegate
        RowLayout {
            property TransactionAmount amount: modelData

            spacing: 16

            Label {
                text: amount.formatAmount(wallet.settings.unit)
            }
        }
    }

    contentItem: ScrollView {
        id: scroll_view
        clip: true

        ColumnLayout {
            width: scroll_view.width - constants.p2
            spacing: constants.p3

            ColumnLayout {
                spacing: constants.p0

                SectionLabel {
                    text: qsTrId('id_received_on')
                }

                CopyableLabel {
                    text: formatTransactionTimestamp(transaction.data)
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
                    text: qsTrId('id_transaction_status')
                }

                Label {
                    text: transactionStatus(confirmations)
                    font.pixelSize: 12
                    font.styleName: 'Medium'
                    font.capitalization: Font.AllUppercase
                    topPadding: 4
                    bottomPadding: 4
                    leftPadding: 12
                    rightPadding: 12
                    background: Rectangle {
                        radius: 4
                        color: confirmations === 0 ? '#d2934a' : '#474747'
                    }
                }
            }

            ColumnLayout {
                spacing: constants.p0

                SectionLabel {
                    text: qsTrId('id_amount')
                }

                Repeater {
                    model: transaction.amounts
                    delegate: wallet.network.liquid ? liquid_amount_delegate : bitcoin_amount_delegate
                }
            }

            ColumnLayout {
                spacing: constants.p0

                SectionLabel {
                    visible: transaction.data.type === 'outgoing'
                    text: qsTrId('id_fee')
                }

                CopyableLabel {
                    visible: transaction.data.type === 'outgoing'
                    text: `${transaction.data.fee / 100000000} ${wallet.network.liquid ? 'Liquid Bitcoin' : 'BTC'} (${Math.round(transaction.data.fee_rate / 1000)} sat/vB)`
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
                    width: scroll_view.width - constants.p2
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
        HSpacer {
        }
        GButton {
            visible: transaction.data.can_rbf
            text: qsTrId('id_increase_fee')
            onClicked: {
                bump_fee_dialog.createObject(window, { transaction  }).open()
                self.accept()
            }
        }
        GButton {
            text: qsTrId('id_view_in_explorer')
            onClicked: transaction.openInExplorer()
        }
        GButton {
            text: qsTrId('id_copy_unblinded_link')
            visible: transaction.account.wallet.network.liquid
            onClicked: {
                Clipboard.copy(transaction.unblindedLink())
                ToolTip.show(qsTrId('id_copied_to_clipboard'), 1000)
            }
        }
        GButton {
            text: qsTrId('id_copy_unblinding_data')
            visible: transaction.account.wallet.network.liquid
            onClicked: copyUnblindingData(this, transaction.data)
        }
    }
}
