import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

StackViewPage {
    signal closed()
    required property Transaction transaction
    readonly property Context context: self.transaction.account.context
    property bool note: self.transaction.memo !== ''
    readonly property Network network: self.transaction.account.network
    readonly property int confirmations: transactionConfirmations(self.transaction)
    readonly property bool completed: self.confirmations >= (self.network.liquid ? 2 : 6)
    readonly property var spv: {
        const value = self.transaction.spv
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
    readonly property var amounts: {
        const amounts = []
        for (let [id, satoshi] of Object.entries(self.transaction.data.satoshi)) {
            if (self.network.policyAsset === id && satoshi < 0) {
                satoshi += self.transaction.data.fee
                if (satoshi === 0) continue
            }
            const asset = AssetManager.assetWithId(self.context.deployment, id)
            amounts.push({ asset, satoshi: String(satoshi) })
        }
        return amounts
    }
    readonly property color tx_color: {
        if (self.confirmations === 0) return '#BB7B00'
        if (self.confirmations > self.network.liquid ? 2 : 6) return '#0A9252'
        return '#929292'
        // switch (self.transaction.type) {
        //     case Transaction.Incoming: return '#0A9252'
        //     case Transaction.Outgoing: return '#FFF'
        //     case Transaction.Redeposit: return '#929292'
        //     case Transaction.Mixed: return '#0A9252'
        // }
    }

    AnalyticsView {
        name: 'TransactionDetails'
        active: true
        segmentation: AnalyticsJS.segmentationSubAccount(self.transaction.account)
    }

    id: self
    title: qsTrId('id_transaction_details')
    rightItem: RowLayout {
        spacing: 20
        // CircleButton {
        //     icon.source: 'qrc:/svg2/qrcode.svg'
        // }
        ShareButton {
            onClicked: self.transaction.openInExplorer()
        }
        CloseButton {
            onClicked: self.closed()
        }
    }
    contentItem: Flickable {
        ScrollIndicator.vertical: ScrollIndicator {
        }
        id: flickable
        clip: true
        contentWidth: flickable.width
        contentHeight: layout.height
        ColumnLayout {
            id: layout
            spacing: 10
            width: flickable.width
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
                        }
                    }
                }
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
                    if (self.completed) {
                        parts.push('Completed')
                    } else {
                        parts.push('Confirming')
                        parts.push(`(${self.confirmations}/${self.network.liquid ? 2 : 6})`)
                    }
                    return parts.join(' ')
                }
            }

            Label {
                Layout.alignment: Qt.AlignCenter
                font.pixelSize: 12
                font.weight: 400
                color: '#929292'
                text: UtilJS.formatTransactionTimestamp(self.transaction.data)
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                topPadding: 3
                bottomPadding: 3
                leftPadding: 8
                rightPadding: 8
                color: '#FFF'
                font.pixelSize: 12
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
                            RowLayout {
                                Layout.alignment: self.transaction.type === Transaction.Mixed ? Qt.AlignRight : Qt.AlignCenter
                                Layout.fillWidth: false
                                Label {
                                    Layout.alignment: Qt.AlignBaseline
                                    font.pixelSize: 24
                                    font.weight: 500
                                    text: convert.output.amount
                                }
                                Label {
                                    Layout.alignment: Qt.AlignBaseline
                                    color: '#4EC08A'
                                    font.pixelSize: 12
                                    font.weight: 400
                                    text: convert.output.unit
                                }
                            }
                            Label {
                                Layout.alignment: self.transaction.type === Transaction.Mixed ? Qt.AlignRight : Qt.AlignCenter
                                font.pixelSize: 14
                                font.weight: 400
                                opacity: 0.6
                                text: convert.fiat.label
                                visible: convert.fiat.available
                            }
                        }
                    }
                }
            }
            LineSeparator {
                Layout.bottomMargin: 20
                Layout.topMargin: 20
            }
            GridLayout {
                rowSpacing: 10
                columnSpacing: 20
                columns: 2
                Label {
                    Layout.minimumWidth: 100
                    color: '#929292'
                    font.pixelSize: 12
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
                    Label {
                        topPadding: 4
                        bottomPadding: 4
                        color: '#FFF'
                        font.pixelSize: 12
                        font.weight: 400
                        text: fee_convert.output.label
                    }
                    Label {
                        Layout.fillWidth: true
                        topPadding: 4
                        bottomPadding: 4
                        color: '#FFF'
                        font.pixelSize: 12
                        font.weight: 400
                        opacity: 0.6
                        text: '~ ' + fee_convert.fiat.label
                    }
                }
                Label {
                    color: '#929292'
                    font.pixelSize: 12
                    font.weight: 400
                    text: qsTrId('id_fee_rate')
                }
                Label {
                    Layout.fillWidth: true
                    topPadding: 4
                    bottomPadding: 4
                    color: '#FFF'
                    font.pixelSize: 12
                    font.weight: 400
                    text: `${Math.ceil(self.transaction.data.fee_rate / 1000)} sat/vbyte`
                }
                Label {
                    id: address_left_label
                    color: '#929292'
                    font.pixelSize: 12
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
                    visible: address_left_label.text !== ''
                }
                TLabel {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    id: address_right_label
                    color: '#FFF'
                    elide: Label.ElideMiddle
                    font.pixelSize: 12
                    font.weight: 400
                    text: {
                        if (!self.network.liquid && self.transaction.type === Transaction.Outgoing) {
                            return self.transaction.data.outputs
                                .filter(output => !output.is_relevant)
                                .map(output => output.address)
                                .join('\n')
                        }
                        if (!self.network.liquid && self.transaction.type === Transaction.Incoming) {
                            return self.transaction.data.outputs
                                .filter(output => output.is_relevant)
                                .map(output => output.address)
                                .join('\n')
                        }
                        return ''
                    }
                    visible: address_right_label.text !== ''
                }
                Label {
                    color: '#929292'
                    font.pixelSize: 12
                    font.weight: 400
                    text: qsTrId('id_transaction_id')
                }
                TLabel {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    color: '#FFF'
                    elide: Label.ElideMiddle
                    font.pixelSize: 12
                    font.weight: 400
                    text: self.transaction.data.txhash
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
                        Layout.bottomMargin: 20
                        Layout.topMargin: 20
                    }
                    FieldTitle {
                        text: qsTrId('id_note')
                    }
                    TextArea {
                        Layout.fillWidth: true
                        id: note_text_area
                        topPadding: 20
                        bottomPadding: 20
                        leftPadding: 20
                        rightPadding: 20
                        text: self.transaction.memo
                        wrapMode: TextArea.Wrap
                        background: Rectangle {
                            color: Qt.lighter('#222226', note_text_area.hovered ? 1.2 : 1)
                            radius: 5
                        }
                        onEditingFinished: self.transaction.updateMemo(note_text_area.text)
                    }
                }
            }
            ColumnLayout {
                Layout.topMargin: 20
                spacing: -1
                ActionButton {
                    icon.source: 'qrc:/svg2/gauge-green.svg'
                    text: 'Speed up Transaction'
                    badge: qsTrId('id_increase_fee')
                    visible: self.transaction?.data.can_rbf ?? false
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
                ActionButton {
                    icon.source: 'qrc:/svg2/copy-green.svg'
                    text: qsTrId('id_copy_unblinded_link')
                    visible: self.network.liquid
                    onClicked: {
                        Clipboard.copy(self.transaction.unblindedLink())
                    }

                }
                ActionButton {
                    icon.source: 'qrc:/svg2/copy-green.svg'
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
            // TODO Analytics.recordEvent('share_transaction', AnalyticsJS.segmentationShareTransaction(self.transaction.account))
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
    }

    component ActionButton: AbstractButton {
        property string badge
        Layout.fillWidth: true
        id: button
        leftPadding: 2
        rightPadding: 2
        topPadding: 12
        bottomPadding: 12
        background: Rectangle {
            color: Qt.alpha('#FFF', button.hovered ? 0.05 : 0)
            LineSeparator {
                width: parent.width
            }
            LineSeparator {
                width: parent.width
                y: parent.height - 1
            }
        }
        contentItem: RowLayout {
            Image {
                source: button.icon.source
            }
            Label {
                Layout.fillWidth: true
                color: '#0A9252'
                text: button.text
            }
            Label {
                leftPadding: 8
                rightPadding: 8
                topPadding: 3
                bottomPadding: 3
                background: Rectangle {
                    color: '#0A9252'
                    radius: height / 2
                }
                font.pixelSize: 12
                font.weight: 700
                text: button.badge ?? ''
                visible: button.badge
            }
        }
    }

    component LineSeparator: Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        height: 1
        color: '#313131'
    }

        /*
        GToolButton {
            icon.source: 'qrc:/svg/qr.svg'
            onClicked: qrcode_popup.open()
            QRCodePopup {
                id: qrcode_popup
                text: self.network.liquid ? self.transaction.unblindedLink() : self.transaction.link()
            }
        }
        */

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
                        Label {
                            text: amount.asset.name
                            font.pixelSize: 14
                            elide: Label.ElideRight
                        }
                        Loader {
                            active: !!amount.asset.data.entity
                            visible: active
                            sourceComponent: Label {
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
                        Label {
                            Layout.alignment: Qt.AlignRight
                            text: {
                                self.transaction.account.session.displayUnit
                                return amount.formatAmount(true)
                            }
                            color: amount.amount > 0 ? '#00b45a' : 'white'
                            font.pixelSize: 16
                            font.styleName: 'Medium'
                        }
                        Label {
                            Layout.alignment: Qt.AlignRight
                            text: {
                                return `≈ ${copyText}`
                            }
                            //copyText: visible ? formatFiat(amount.amount) : ''
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
                Label {
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
                        Label {
                            Layout.alignment: Qt.AlignRight
                            text: `${transaction.type === Transaction.Outgoing ? '-' : ''}${satoshi}`
                            color: transaction.type === Transaction.Incoming ? '#00b45a' : 'white'
                            font.pixelSize: 16
                            font.styleName: 'Medium'
                        }
                        Label {
                            Layout.alignment: Qt.AlignRight
                            //text: `≈ ${copyText}`
                            //copyText: `${transaction.type === Transaction.Outgoing ? '-' : ''}${formatFiat(transaction.type === Transaction.Outgoing ? output.satoshi : amount.amount)}`
                            opacity: 0.5
                        }
                    }
                }
            }
        }
    }

    Component {
        id: details_page
        StackViewPage {
            title: self.title
            rightItem: RowLayout {
                spacing: 20
                ShareButton {
                    url: self.transaction.url
                }
                CloseButton {
                    onClicked: self.closed()
                }
            }
            contentItem: Flickable {
                ScrollIndicator.vertical: ScrollIndicator {
                }
                id: flickable
                clip: true
                contentWidth: flickable.width
                contentHeight: layout.height
                ColumnLayout {
                    id: layout
                    spacing: 10
                    width: flickable.width
                    TextArea {
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
    }

    component TLabel: Label {
        id: label
        topPadding: 4
        bottomPadding: 4
        rightPadding: hover_handler.hovered ? 32 : 0
        Image {
            source: timer.running ? 'qrc:/svg2/check.svg' : 'qrc:/svg2/copy.svg'
            visible: hover_handler.hovered
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
        }
        HoverHandler {
            id: hover_handler
        }
        TapHandler {
            onTapped: {
                Clipboard.copy(label.text)
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
            transaction: self.transaction
            onClosed: self.closed()
        }
    }
}
