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
    readonly property bool completed: confirmations >= (network.liquid ? 2 : 6)

    wallet: transaction.account.wallet
    title: {
        switch (transaction.type) {
            case Transaction.Incoming: return qsTrId('id_incoming')
            case Transaction.Outgoing: return qsTrId('id_outgoing')
            case Transaction.Redeposit: return qsTrId('id_redeposited')
        }
    }

    readonly property var spv: {
        const value = transaction.spv
        if (value === Transaction.Disabled) return null
        if (!completed) return null
        switch (value) {
        case Transaction.Unconfirmed:
            return null
        case Transaction.Verified:
            return { value, color: constants.g500, icon: 'qrc:/svg/tx-spv-verified.svg', text: qsTrId('id_verified') }
        case Transaction.NotVerified:
            return { value, color: constants.r500, icon: 'qrc:/svg/tx-spv-not-verified.svg', text: qsTrId('id_invalid_merkle_proof') }
        case Transaction.NotLongest:
            return { value, color: constants.r500, icon: 'qrc:/svg/tx-spv-not-longest.svg', text: qsTrId('id_not_on_longest_chain') }
        case Transaction.InProgress:
            return { value, color: constants.g500, icon: 'qrc:/svg/tx-spv-in-progress.svg', text: qsTrId('id_verifying_transactions') }
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
            contentItem: ColumnLayout {
                spacing: 16
                RowLayout {
                    spacing: 16
                    AssetIcon {
                        asset: amount.asset
                    }
                    ColumnLayout {
                        CopyableLabel {
                            Layout.fillWidth: true
                            text: amount.asset.name
                            font.pixelSize: 14
                            elide: Label.ElideRight
                        }
                        CopyableLabel {
                            visible: text != ''
                            Layout.fillWidth: true
                            opacity: 0.5
                            text: 'entity' in amount.asset.data ? amount.asset.data.entity.domain : ''
                            elide: Label.ElideRight
                        }
                    }
                    HSpacer {
                    }
                    CopyableLabel {
                        text: {
                            wallet.displayUnit
                            return amount.formatAmount(true)
                        }
                        color: amount.transaction.type === Transaction.Incoming ? '#00b45a' : 'white'
                        font.pixelSize: 16
                        font.styleName: 'Medium'
                    }
                }
            }
        }
    }

    Component {
        id: bitcoin_amount_delegate
        GPane {
            property TransactionAmount amount: modelData
            readonly property var output: {
                if (transaction.type === Transaction.Outgoing) {
                    for (const output of transaction.data.outputs) {
                        if (!output.is_relevant) return output
                    }
                }
            }
            readonly property string satoshi: {
                wallet.displayUnit;
                const unit = wallet.settings.unit;
                if (output) {
                    return wallet.formatAmount(output.satoshi, true, unit);
                } else {
                    return amount.formatAmount(true)
                }
            }

            Layout.fillWidth: true
            background: Rectangle {
                color: constants.c600
                radius: 4
            }
            contentItem: ColumnLayout {
                spacing: constants.s1
                SectionLabel {
                    visible: transaction.type === Transaction.Outgoing
                    text: qsTrId('id_recipient')
                }
                CopyableLabel {
                    visible: !!output
                    text: output ? output.address : ''
                }
                RowLayout {
                    spacing: constants.s1
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
                    CopyableLabel {
                        text: (transaction.type === Transaction.Outgoing ? '-' : '') + satoshi
                        copyText: satoshi
                        color: transaction.type === Transaction.Incoming ? '#00b45a' : 'white'
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

            Repeater {
                visible: count > 0
                model: transaction.type === Transaction.Redeposit ? [] : transaction.amounts
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
                    RowLayout {
                        CopyableLabel {
                            Layout.alignment: Qt.AlignRight
                            text: formatAmount(transaction.data.fee)
                        }
                        CopyableLabel {
                            Layout.alignment: Qt.AlignRight
                            text: `≈ ` + formatFiat(transaction.data.fee)
                            copyText: formatFiat(transaction.data.fee)
                        }
                        CopyableLabel {
                            Layout.alignment: Qt.AlignRight
                            text: `(${transaction.data.fee_rate / 1000} satoshi/vbyte)`
                            copyText: `${transaction.data.fee_rate / 1000} satoshi/vbyte`
                        }
                    }
                }
            }

            RowLayout {
                visible: confirmations === 0 && !transaction.account.wallet.watchOnly && !network.liquid && (transaction.type === Transaction.Redeposit || transaction.type === Transaction.Outgoing)
                HSpacer {
                }
                GButton {
                    large: true
                    highlighted: confirmations === 0
                    text: qsTrId('id_increase_fee')
                    enabled: transaction.data.can_rbf
                    onClicked: {
                        bump_fee_dialog.createObject(window, { transaction }).open()
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
                    GPane {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        padding: 0
                        contentItem: ColumnLayout {
                            spacing: constants.s1
                            CopyableLabel {
                                font.pixelSize: 12
                                text: formatTransactionTimestamp(transaction.data)
                            }
                            VSpacer {
                            }
                            Label {
                                color: 'white'
                                text: {
                                    if (confirmations === 0) return qsTrId('id_unconfirmed')
                                    if (!completed) return qsTrId('id_pending_confirmation')
                                    if (!spv) return qsTrId('id_completed')
                                    return spv.text
                                }
                                font.pixelSize: 12
                                font.styleName: 'Medium'
                                font.capitalization: Font.AllUppercase

                                topPadding: 4
                                bottomPadding: 4
                                leftPadding: 12
                                rightPadding: 12
                                background: Rectangle {
                                    radius: 4
                                    color: {
                                        if (confirmations === 0) return '#d2934a'
                                        if (!completed) return '#474747'
                                        return spv ? spv.color : constants.g500
                                    }
                                }
                            }
                        }
                    }
                    TransactionProgress {
                        implicitWidth: 48
                        implicitHeight: 48
                        max: network.liquid ? 2 : 6
                        current: confirmations
                        indeterminate: spv && spv.value === Transaction.InProgress
                        icon: spv ? spv.icon : 'qrc:/svg/check.svg'
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
        GToolButton {
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
