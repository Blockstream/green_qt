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
    readonly property Context context: self.transaction.account.context
    property bool note: self.transaction.memo !== ''
    readonly property Network network: self.transaction.account.network
    readonly property int confirmations: transactionConfirmations(self.transaction)
    readonly property bool completed: self.confirmations >= (self.network.liquid ? 2 : 6)
    readonly property var amounts: {
        const amounts = []
        if (self.transaction.type !== Transaction.Redeposit) {
            for (let [id, satoshi] of Object.entries(self.transaction.data.satoshi)) {
                if (self.network.policyAsset === id && satoshi < 0) {
                    satoshi += self.transaction.data.fee
                    if (satoshi === 0) continue
                }
                const asset = AssetManager.assetWithId(self.context.deployment, id)
                amounts.push({ asset, satoshi: String(satoshi) })
            }
        }
        return amounts
    }
    readonly property var totals: {
        const totals = []
        if (self.transaction.type !== Transaction.Redeposit) {
            for (let [id, satoshi] of Object.entries(self.transaction.data.satoshi)) {
                const asset = AssetManager.assetWithId(self.context.deployment, id)
                totals.push({ asset, satoshi: String(satoshi) })
            }
        }
        return totals
    }
    readonly property color tx_color: {
        if (self.confirmations === 0) return '#BB7B00'
        if (self.confirmations > self.network.liquid ? 2 : 6) return '#00BCFF'
        return '#929292'
    }

    AnalyticsView {
        name: 'TransactionDetails'
        active: true
        segmentation: AnalyticsJS.segmentationSubAccount(Settings, self.transaction.account)
    }

    id: self
    title: qsTrId('id_transaction_details')
    rightItem: RowLayout {
        spacing: 20
        ShareButton {
            url: ''
            onClicked: self.transaction.openInExplorer()
        }
        CloseButton {
            onClicked: self.closeClicked()
        }
    }
    contentItem: VFlickable {
        alignment: Qt.AlignTop
        spacing: 10
        Item {
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: 96
            Layout.preferredHeight: 96
            Rectangle {
                anchors.centerIn: parent
                height: 72
                width: 72
                radius: 36
                color: self.tx_color
                ProgressIndicator {
                    indeterminate: self.confirmations === 0
                    current: self.confirmations <= (self.network.liquid ? 2 : 6) ? self.confirmations : 0
                    max: self.network.liquid ? 2 : 6
                    anchors.fill: parent
                    anchors.margins: -1
                }
            }
            Image {
                anchors.centerIn: parent
                source: `qrc:/svg2/tx-${transaction.data.type}.svg`
                width: 32
                height: 32
            }
            RowLayout {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                visible: self.transaction.type !== Transaction.Mixed
                Repeater {
                    model: self.amounts
                    delegate: AssetIcon {
                        asset: modelData.asset
                        border: 2
                        borderColor: '#000'
                    }
                }
            }
        }
        TransactionStatusBadge {
            Layout.alignment: Qt.AlignCenter
            confirmations: self.confirmations
            transaction: self.transaction
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            font.pixelSize: 24
            font.weight: 600
            text: {
                const parts = []
                if (self.transaction.type === Transaction.Mixed) {
                    parts.push('Swap')
                } else {
                    parts.push('Transaction')
                }
                return parts.join(' ')
            }
        }
        TLabel {
            Layout.alignment: Qt.AlignCenter
            font.pixelSize: 14
            font.weight: 400
            color: '#929292'
            text: UtilJS.formatTransactionTimestamp(self.transaction)
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            topPadding: 3
            bottomPadding: 3
            leftPadding: 8
            rightPadding: 8
            color: '#FFF'
            font.pixelSize: 14
            font.weight: 700
            text: {
                switch (self.transaction.type) {
                    case Transaction.Incoming: return qsTrId('id_received')
                    case Transaction.Outgoing: return qsTrId('id_sent')
                    case Transaction.Redeposit: return qsTrId('id_redeposited')
                    case Transaction.Mixed: return qsTrId('id_swap')
                }
            }
            background: Rectangle {
                color: self.tx_color
                radius: height / 2
            }
        }
        Repeater {
            model: self.amounts
            delegate: Pane {
                required property var modelData
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: self.transaction.type === Transaction.Mixed
                id: amount_pane
                background: null
                padding: 0
                Convert {
                    id: convert
                    account: self.transaction.account
                    asset: amount_pane.modelData.asset
                    input: ({ satoshi: String(amount_pane.modelData.satoshi) })
                    unit: self.transaction.account.session.unit
                }
                contentItem: RowLayout {
                    AssetIcon {
                        asset: amount_pane.modelData.asset
                        visible: self.transaction.type === Transaction.Mixed
                    }
                    HSpacer {
                        visible: self.transaction.type === Transaction.Mixed
                    }
                    ColumnLayout {
                        spacing: 4
                        TLabel {
                            Layout.alignment: self.transaction.type === Transaction.Mixed ? Qt.AlignRight : Qt.AlignCenter
                            Layout.fillWidth: false
                            copyText: convert.output.label
                            font.family: 'Roboto Mono'
                            font.features: { 'calt': 0, 'zero': 1 }
                            font.pixelSize: 24
                            font.weight: 500
                            text: UtilJS.incognito(Settings.incognito, convert.output.label)
                        }
                        TLabel {
                            Layout.alignment: self.transaction.type === Transaction.Mixed ? Qt.AlignRight : Qt.AlignCenter
                            font.family: 'Roboto Mono'
                            font.features: { 'calt': 0, 'zero': 1 }
                            font.pixelSize: 14
                            font.weight: 400
                            opacity: 0.6
                            text: UtilJS.incognito(Settings.incognito, convert.fiat.label)
                            visible: convert.fiat.available
                        }
                    }
                }
            }
        }
        LineSeparator {
            Layout.bottomMargin: 10
            Layout.topMargin: 10
        }
        GridLayout {
            rowSpacing: 10
            columnSpacing: 20
            columns: 2
            Label {
                Layout.minimumWidth: 100
                color: '#929292'
                font.pixelSize: 14
                font.weight: 400
                text: qsTrId('id_network_fee')
            }
            Convert {
                id: fee_convert
                account: self.transaction.account
                input: ({ satoshi: self.transaction.data.fee })
                unit: self.transaction.account.session.unit
            }
            RowLayout {
                TLabel {
                    topPadding: 4
                    bottomPadding: 4
                    color: '#FFF'
                    font.family: 'Roboto Mono'
                    font.features: { 'calt': 0, 'zero': 1 }
                    font.pixelSize: 14
                    font.weight: 400
                    text: UtilJS.incognito(Settings.incognito, fee_convert.output.label)
                }
                TLabel {
                    topPadding: 4
                    bottomPadding: 4
                    color: '#FFF'
                    font.family: 'Roboto Mono'
                    font.features: { 'calt': 0, 'zero': 1 }
                    font.pixelSize: 14
                    font.weight: 400
                    opacity: 0.6
                    text: UtilJS.incognito(Settings.incognito, '~ ' + fee_convert.fiat.label)
                }
                HSpacer {
                }
            }
            Label {
                color: '#929292'
                font.pixelSize: 14
                font.weight: 400
                text: qsTrId('id_fee_rate')
            }
            RowLayout {
                TLabel {
                    topPadding: 4
                    bottomPadding: 4
                    color: '#FFF'
                    font.family: 'Roboto Mono'
                    font.features: { 'calt': 0, 'zero': 1 }
                    font.pixelSize: 14
                    font.weight: 400
                    text: UtilJS.formatFeeRate(self.transaction.data.fee_rate, self.transaction.account.network)
                }
                HSpacer {
                }
            }
            Label {
                Layout.alignment: Qt.AlignTop
                color: '#929292'
                font.pixelSize: 14
                font.weight: 400
                text: {
                    if (!self.network.liquid && self.transaction.type === Transaction.Outgoing) {
                        return qsTrId('id_sent_to')
                    }
                    if (!self.network.liquid && self.transaction.type === Transaction.Incoming) {
                        return qsTrId('id_received_on')
                    }
                    return ''
                }
                visible: address_label_repeater.count > 0
            }
            ColumnLayout {
                visible: address_label_repeater.count > 0
                Repeater {
                    id: address_label_repeater
                    model: {
                        const account = self.transaction.account
                        if (!self.network.liquid && self.transaction.type === Transaction.Outgoing) {
                            return self.transaction.data.outputs
                                .filter(output => !output.is_relevant)
                                .map(output => account.getOrCreateAddress(output))
                        }
                        if (!self.network.liquid && self.transaction.type === Transaction.Incoming) {
                            return self.transaction.data.outputs
                                .filter(output => output.is_relevant)
                                .map(output => account.getOrCreateAddress(output))
                        }
                        return []
                    }
                    delegate: AddressLabel {
                        required property var modelData
                        Layout.fillWidth: true
                        id: delegate
                        address: delegate.modelData
                        copyEnabled: true
                        elide: AddressLabel.ElideNone
                        font.pixelSize: 14
                        font.weight: 400
                        horizontalAlignment: Text.AlignLeft
                    }
                }
            }
            Label {
                Layout.alignment: Qt.AlignTop
                color: '#929292'
                font.pixelSize: 14
                font.weight: 400
                text: qsTrId('id_transaction_id')
            }
            TLabel {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                color: '#FFF'
                elide: Label.ElideMiddle
                font.family: 'Roboto Mono'
                font.features: { 'calt': 0, 'zero': 1 }
                font.pixelSize: 14
                font.weight: 400
                text: self.transaction.data.txhash
                onCopyClicked: Analytics.recordEvent('share_transaction', AnalyticsJS.segmentationShareTransaction(Settings, self.transaction.account))
            }
        }
        LineSeparator {
            Layout.bottomMargin: 10
            Layout.topMargin: 10
            visible: self.transaction.type === Transaction.Outgoing
        }
        GridLayout {
            rowSpacing: 10
            columnSpacing: 20
            columns: 2
            visible: self.transaction.type === Transaction.Outgoing
            Label {
                Layout.alignment: Qt.AlignTop
                Layout.minimumWidth: 100
                color: '#929292'
                font.pixelSize: 14
                font.weight: 400
                text: qsTrId('id_total_spent')
            }
            ColumnLayout {
                Repeater {
                    model: self.totals
                    delegate: Pane {
                        required property var modelData
                        Layout.fillWidth: true
                        id: total_pane
                        background: null
                        padding: 0
                        Convert {
                            id: total_convert
                            account: self.transaction.account
                            asset: total_pane.modelData.asset
                            input: ({ satoshi: String(total_pane.modelData.satoshi) })
                            unit: self.transaction.account.session.unit
                        }
                        contentItem: ColumnLayout {
                            spacing: 4
                            TLabel {
                                Layout.alignment: Qt.AlignRight
                                Layout.fillWidth: false
                                copyText: total_convert.output.label
                                font.family: 'Roboto Mono'
                                font.features: { 'calt': 0, 'zero': 1 }
                                font.pixelSize: 14
                                font.weight: 400
                                text: UtilJS.incognito(Settings.incognito, total_convert.output.label)
                            }
                            TLabel {
                                Layout.alignment: Qt.AlignRight
                                font.family: 'Roboto Mono'
                                font.features: { 'calt': 0, 'zero': 1 }
                                font.pixelSize: 14
                                font.weight: 400
                                opacity: 0.6
                                text: UtilJS.incognito(Settings.incognito, total_convert.fiat.label)
                                visible: total_convert.fiat.available
                            }
                        }
                    }
                }
            }
        }
        Collapsible {
            Layout.fillWidth: true
            id: note_collapsible
            animationVelocity: 300
            collapsed: !self.note
            contentWidth: note_collapsible.width
            contentHeight: note_layout.height
            ColumnLayout {
                id: note_layout
                width: note_collapsible.width
                LineSeparator {
                    Layout.bottomMargin: 10
                }
                FieldTitle {
                    text: qsTrId('id_note')
                }
                GTextArea {
                    Layout.fillWidth: true
                    id: note_text_area
                    enabled: !self.context.watchonly
                    topPadding: 20
                    bottomPadding: 20
                    leftPadding: 20
                    rightPadding: 20
                    text: self.transaction.memo
                    wrapMode: TextArea.Wrap
                    onEditingFinished: {
                        if (!self.context.watchonly) {
                           self.transaction.updateMemo(note_text_area.text)
                        }
                    }
                }
            }
        }
        VSpacer {
        }
        ColumnLayout {
            Layout.topMargin: 20
            Layout.fillHeight: false
            spacing: -1
            ActionButton {
                icon.source: 'qrc:/svg2/gauge-green.svg'
                text: 'Speed up Transaction'
                badge: qsTrId('id_increase_fee')
                visible: !self.network.liquid && (self.transaction?.data?.can_rbf ?? false)
                onClicked: self.StackView.view.push(rbf_page)
            }
            ActionButton {
                icon.source: 'qrc:/svg2/pencil-simple-line-green.svg'
                text: qsTrId('id_add_note')
                visible: !self.note
                onClicked: {
                    self.note = true
                    note_text_area.forceActiveFocus()
                }
            }
            CopyActionButton {
                text: qsTrId('id_copy_unblinded_link')
                visible: self.network.liquid
                onClicked: {
                    Clipboard.copy(self.transaction.unblindedLink())
                    Analytics.recordEvent('share_transaction', AnalyticsJS.segmentationShareTransaction(Settings, self.transaction.account))
                }

            }
            CopyActionButton {
                text: qsTrId('id_copy_unblinding_data')
                visible: self.network.liquid
                onClicked: {
                    const data = JSON.stringify(UtilJS.getUnblindingData(self.transaction.data), null, '  ')
                    Clipboard.copy(data)
                }
            }
            ActionButton {
                icon.source: 'qrc:/svg2/dots-three-green.svg'
                text: qsTrId('id_show_details')
                onClicked: self.StackView.view.push(details_page)
            }
        }
/*
        // TODO Analytics.recordEvent('share_transaction', AnalyticsJS.segmentationShareTransaction(Settings, self.transaction.account))
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
        */
    }

    component ActionButton: AbstractButton {
        property string badge
        Layout.fillWidth: true
        id: button
        leftPadding: 4
        rightPadding: 4
        topPadding: 8
        bottomPadding: 8
        background: Rectangle {
            color: Qt.alpha('#FFF', button.enabled && button.hovered ? 0.05 : 0)
            LineSeparator {
                width: parent.width
            }
            LineSeparator {
                width: parent.width
                y: parent.height - 1
            }
        }
        contentItem: RowLayout {
            opacity: button.enabled ? 1 : 0.5
            Image {
                source: button.icon.source
            }
            Label {
                Layout.fillWidth: true
                color: '#00BCFF'
                text: button.text
            }
            Label {
                leftPadding: 8
                rightPadding: 8
                topPadding: 3
                bottomPadding: 3
                background: Rectangle {
                    color: '#00BCFF'
                    radius: height / 2
                }
                font.pixelSize: 14
                font.weight: 700
                text: button.badge ?? ''
                visible: button.badge
            }
        }
    }

    component CopyActionButton: ActionButton {
        icon.source: timer.running ? 'qrc:/svg2/check-green.svg' : 'qrc:/svg2/copy-green.svg'
        onClicked: timer.restart()
        Timer {
            id: timer
            repeat: false
            interval: 1000
        }
    }

    component LineSeparator: Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        height: 1
        color: '#313131'
    }

    Component {
        id: details_page
        StackViewPage {
            title: self.title
            rightItem: RowLayout {
                spacing: 20
                ShareButton {
                    url: self.transaction.url ?? ''
                }
                CloseButton {
                    onClicked: self.closeClicked()
                }
            }
            contentItem: VFlickable {
                GTextArea {
                    Layout.preferredWidth: 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: raw_text_area.contentHeight
                    id: raw_text_area
                    font.pixelSize: 8
                    text: JSON.stringify(self.transaction.data, null, '  ')
                    wrapMode: Label.Wrap
                }
            }
        }
    }

    component TLabel: Label {
        signal copyClicked()
        property string copyText: label.text
        id: label
        rightPadding: collapsible.width
        Collapsible {
            id: collapsible
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            animationVelocity: 500
            collapsed: !hover_handler.hovered
            horizontalCollapse: true
            verticalCollapse: false
            Image {
                x: 8
                source: timer.running ? 'qrc:/svg2/check.svg' : 'qrc:/svg2/copy.svg'
            }
        }
        HoverHandler {
            id: hover_handler
        }
        TapHandler {
            onTapped: {
                Clipboard.copy(label.copyText)
                label.copyClicked()
                timer.restart()
            }
        }
        Timer {
            id: timer
            repeat: false
            interval: 1000
        }
    }

    Component {
        id: rbf_page
        SendPage {
            title: qsTrId('id_increase_fee')
            context: self.transaction.account.context
            account: self.transaction.account
            asset: self.context.getOrCreateAsset(network.policyAsset)
            transaction: self.transaction
            onCloseClicked: self.closeClicked()
        }
    }
}
