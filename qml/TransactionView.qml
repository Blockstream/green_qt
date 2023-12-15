import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

StackViewPage {
    required property Transaction transaction
    property Action closeAction

    readonly property Network network: self.transaction.account.network
    readonly property int confirmations: transactionConfirmations(self.transaction)
    readonly property bool completed: self.confirmations >= (self.network.liquid ? 2 : 6)
    readonly property var spv: {
        const value = self.transaction. spv
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

    AnalyticsView {
        name: 'TransactionDetails'
        active: self.opened
        segmentation: AnalyticsJS.segmentationSubAccount(self.transaction.account)
    }

    id: self
    title: {
        switch (self.transaction.type) {
            case Transaction.Incoming: return qsTrId('id_incoming')
            case Transaction.Outgoing: return qsTrId('id_outgoing')
            case Transaction.Redeposit: return qsTrId('id_redeposited')
            case Transaction.Mixed: return qsTrId('id_swap')
        }
    }
    rightItem: RowLayout {
        spacing: 20
        CircleButton {
            icon.source: 'qrc:/svg2/qrcode.svg'
        }
        ShareButton {
            onClicked: Qt.openUrlExternally(self.transaction.account.network.data.tx_explorer_url + self.transaction.data.txhash)
        }
        CloseButton {
            action: self.closeAction
            visible: self.closeAction
        }
    }
    contentItem: Flickable {
        ScrollIndicator.vertical: ScrollIndicator {
        }
        id: flickable
        contentWidth: flickable.width
        contentHeight: layout.height
        ColumnLayout {
            id: layout
            spacing: 10
            width: flickable.width
            Repeater {
                visible: count > 0
                model: self.transaction.amounts
                delegate: self.network.liquid ? liquid_amount_delegate : bitcoin_amount_delegate
            }
            ColumnLayout {
                Layout.leftMargin: constants.s1
                Layout.rightMargin: constants.s1
                spacing: constants.p0

                RowLayout {
                    spacing: 16
                    Label {
                        text: qsTrId('id_fee')
                    }
                    HSpacer {
                    }
                    RowLayout {
                        Layout.fillWidth: false
                        CopyableLabel {
                            text: UtilJS.formatAmount(self.transaction.account, transaction.data.fee)
                        }
                        Label {
                            text: '≈'
                        }
                        CopyableLabel {
                            text: UtilJS.formatFiat(self.transaction.account, transaction.data.fee)
                        }
                    }
                }
                RowLayout {
                    spacing: 16
                    HSpacer {
                    }
                    CopyableLabel {
                        opacity: 0.5
                        Layout.alignment: Qt.AlignRight
                        text: `${transaction.data.fee_rate / 1000} satoshi/vbyte`
                    }
                }
                Rectangle {
                    visible: total_with_fee.visible
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: constants.c500
                }
                RowLayout {
                    id: total_with_fee
                    visible: {
                        const network = transaction.account.network
                        if (network.liquid) {
                            const satoshi = transaction.data.satoshi[network.policyAsset] || 0
                            return satoshi < -transaction.data.fee
                        } else {
                            return transaction.type === Transaction.Outgoing
                        }
                    }
                    spacing: 16
                    Label {
                        text: qsTrId('id_total_with_fee')
                    }
                    HSpacer {
                    }
                    RowLayout {
                        Layout.fillWidth: false
                        CopyableLabel {
                            text: UtilJS.formatAmount(transaction.account, transaction.data.satoshi[network.liquid ? network.policyAsset : 'btc'])
                        }
                        Label {
                            text: '≈'
                        }
                        CopyableLabel {
                            text: UtilJS.formatFiat(transaction.account, transaction.data.satoshi[network.liquid ? network.policyAsset : 'btc'])
                        }
                    }
                }
            }
            RowLayout {
                visible: confirmations === 0 && !transaction.account.context.wallet.watchOnly && !network.liquid && (transaction.type === Transaction.Redeposit || transaction.type === Transaction.Outgoing)
                HSpacer {
                }
                GButton {
                    highlighted: confirmations === 0
                    text: qsTrId('id_increase_fee')
                    enabled: transaction.data.can_rbf
                    onClicked: {
                        self.close()
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
                padding: constants.p1
                contentItem: RowLayout {
                    GPane {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        padding: 0
                        contentItem: ColumnLayout {
                            CopyableLabel {
                                font.pixelSize: 12
                                text: UtilJS.formatTransactionTimestamp(transaction.data)
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
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    text: transaction.data.txhash
                    onCopy: Analytics.recordEvent('share_transaction', AnalyticsJS.segmentationShareTransaction(self.transaction.account))
                    wrapMode: Label.Wrap
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
                visible: !wallet.watchOnly
                SectionLabel {
                    text: qsTrId('id_my_notes')
                }
                EditableLabel {
                    id: memo_edit
                    leftPadding: constants.p0
                    rightPadding: constants.p0
                    Layout.fillWidth: true
                    // placeholderText: qsTrId('id_add_a_note_only_you_can_see_it')
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
        }
    }
    footer: RowLayout {
        GToolButton {
            icon.source: 'qrc:/svg/qr.svg'
            onClicked: qrcode_popup.open()
            QRCodePopup {
                id: qrcode_popup
                text: self.network.liquid ? self.transaction.unblindedLink() : self.transaction.link()
            }
        }
        GButton {
            text: qsTrId('id_view_in_explorer')
            onClicked: self.transaction.openInExplorer()
        }
        GButton {
            text: qsTrId('id_copy_unblinded_link')
            visible: self.network.liquid
            onClicked: {
                Clipboard.copy(self.transaction.unblindedLink())
                ToolTip.show(qsTrId('id_copied_to_clipboard'), 1000)
            }
        }
        GButton {
            text: qsTrId('id_copy_unblinding_data')
            visible: self.network.liquid
            onClicked: copyUnblindingData(this, transaction.data)
        }
    }

    Component {
        id: liquid_amount_delegate
        GPane {
            property TransactionAmount amount: modelData
            Layout.fillWidth: true
            padding: constants.p1
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
                            text: amount.asset.name
                            font.pixelSize: 14
                            elide: Label.ElideRight
                        }
                        Loader {
                            active: !!amount.asset.data.entity
                            visible: active
                            sourceComponent: CopyableLabel {
                                opacity: 0.5
                                text: amount.asset.data.entity.domain
                                elide: Label.ElideRight
                            }
                        }

                    }
                    HSpacer {
                    }
                    ColumnLayout {
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        CopyableLabel {
                            Layout.alignment: Qt.AlignRight
                            text: {
                                self.transaction.account.session.displayUnit
                                return amount.formatAmount(true)
                            }
                            color: amount.amount > 0 ? '#00b45a' : 'white'
                            font.pixelSize: 16
                            font.styleName: 'Medium'
                        }
                        CopyableLabel {
                            Layout.alignment: Qt.AlignRight
                            text: {
                                return `≈ ${copyText}`
                            }
                            copyText: visible ? formatFiat(amount.amount) : ''
                            opacity: 0.5
                            visible: amount.asset.isLBTC
                        }
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
                const session = self.transaction.account.session
                session.displayUnit
                if (output) {
                    return wallet.formatAmount(output.satoshi, true, session.unit);
                } else {
                    return amount.formatAmount(true)
                }
            }

            Layout.fillWidth: true
            padding: constants.p1
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
                        source: UtilJS.iconFor(network)
                    }
                    Label {
                        Layout.fillWidth: true
                        text: self.transaction.account.session.displayUnit
                        font.pixelSize: 14
                        elide: Label.ElideRight
                    }
                    HSpacer {
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        CopyableLabel {
                            Layout.alignment: Qt.AlignRight
                            text: `${transaction.type === Transaction.Outgoing ? '-' : ''}${satoshi}`
                            color: transaction.type === Transaction.Incoming ? '#00b45a' : 'white'
                            font.pixelSize: 16
                            font.styleName: 'Medium'
                        }
                        CopyableLabel {
                            Layout.alignment: Qt.AlignRight
                            text: `≈ ${copyText}`
                            copyText: `${transaction.type === Transaction.Outgoing ? '-' : ''}${formatFiat(transaction.type === Transaction.Outgoing ? output.satoshi : amount.amount)}`
                            opacity: 0.5
                        }
                    }
                }
            }
        }
    }

    Component {
        id: bump_fee_dialog
        BumpFeeDialog {
        }
    }
}
