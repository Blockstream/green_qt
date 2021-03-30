import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

Page {
    property Transaction transaction
    property int confirmations: transactionConfirmations(transaction)

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
    Action {
        id: copy_unblinding_data_action
        text: qsTrId('id_copy_unblinding_data')
        onTriggered: copyUnblindingData(tool_button, transaction.data)
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
                text: amount.formatAmount(wallet.settings.unit) // TODO: drop unit here?
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

    background: Item {}

    header: RowLayout {
        ToolButton {
            id: back_arrow_button
            icon.source: 'qrc:/svg/arrow_left.svg'
            icon.height: 16
            icon.width: 16
            onClicked: account_view.pop()
        }

        Label {
            text: qsTrId('id_transaction_details') + ' - ' + tx_direction(transaction.data.type)
            font.pixelSize: 14
            font.capitalization: Font.AllUppercase
            Layout.fillWidth: true
        }

        ToolButton {
            id: tool_button
            text: qsTrId('⋮')
            onClicked: menu.open()
            Layout.rightMargin: constants.p2
            Menu {
                id: menu
                MenuItem {
                    text: qsTrId('id_view_in_explorer')
                    onTriggered: transaction.openInExplorer()
                }
                MenuItem {
                    enabled: transaction.account.wallet.network.liquid
                    text: qsTrId('Copy unblinded link')
                    onTriggered: {
                        Clipboard.copy(transaction.unblindedLink())
                        ToolTip.show(qsTrId('id_copied_to_clipboard'), 1000)
                    }
                }
                Repeater {
                    model: transaction.account.wallet.network.liquid ? [copy_unblinding_data_action] : []
                    MenuItem {
                        action: modelData
                    }
                }
            }
        }
    }

    ScrollView {
        id: scroll_view
        anchors.fill: parent
        anchors.leftMargin: constants.p2
        clip: true

        ColumnLayout {
            width: scroll_view.width - constants.p2
            spacing: constants.p2

            SectionLabel {
                text: qsTrId('id_received_on')
            }
            CopyableLabel {
                text: formatDateTime(transaction.data.created_at)
            }
            SectionLabel {
                text: qsTrId('id_transaction_id')
            }
            CopyableLabel {
                text: transaction.data.txhash
            }
            SectionLabel {
                text: qsTrId('id_transaction_status')
            }
            Label {
                text: transactionStatus(confirmations)
            }
            SectionLabel {
                text: qsTrId('id_amount')
            }
            Repeater {
                model: transaction.amounts
                delegate: wallet.network.liquid ? liquid_amount_delegate : bitcoin_amount_delegate
            }
            SectionLabel {
                visible: transaction.data.type === 'outgoing'
                text: qsTrId('id_fee')
            }
            CopyableLabel {
                visible: transaction.data.type === 'outgoing'
                text: `${transaction.data.fee / 100000000} ${wallet.network.liquid ? 'Liquid Bitcoin' : 'BTC'} (${Math.round(transaction.data.fee_rate / 1000)} sat/vB)`
            }
            SectionLabel {
                text: qsTrId('id_my_notes')
            }
            TextArea {
                id: memo_edit
                Layout.fillWidth: true
                placeholderText: qsTrId('id_add_a_note_only_you_can_see_it')
                width: scroll_view.width - constants.p2
                text: transaction.data.memo
                selectByMouse: true
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    if (text.length > 1024) {
                        memo_edit.text = text.slice(0, 1024);
                    }
                }
            }
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: constants.p2
                GButton {
                    large: true
                    text: qsTrId('id_cancel')
                    enabled: memo_edit.text !== transaction.data.memo
                    onClicked: memo_edit.text = transaction.data.memo
                }
                GButton {
                    large: true
                    text: qsTrId('id_save')
                    enabled: memo_edit.text !== transaction.data.memo
                    onClicked: transaction.updateMemo(memo_edit.text)
                }
            }
        }
    }
}
