import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtQml

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

Page {
    signal transactionClicked(Transaction transaction)
    signal addressClicked(Address transaction)
    required property Context context
    readonly property ContextModel currentModel: (stack_layout.children[stack_layout.currentIndex] as ListPage).model
    function showTransactions(filters) {
        stack_layout.currentIndex = 0
        transaction_model.clearFilters()
        if (filters?.account) transaction_model.setFilterAccount(filters.account)
        if (filters?.asset) transaction_model.setFilterAsset(filters.asset)
    }
    function toggleAccounts() {
        if (accounts_container.width < 1) {
            accounts_container.SplitView.preferredWidth = accounts_container.SplitView.maximumWidth
        } else {
            accounts_container.SplitView.preferredWidth = 0
        }
    }
    id: self
    background: null
    spacing: 32
    header: Pane {
        background: Item {
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: '#414141'
            }
        }
        padding: 0
        contentItem: RowLayout {
            spacing: 4
            TabButton2 {
                Layout.leftMargin: stack_layout.x - 32
                index: 0
                text: qsTrId('id_transactions')
            }
            TabButton2 {
                index: 1
                text: qsTrId('id_addresses')
            }
            TabButton2 {
                index: 2
                text: qsTrId('id_coins')
            }
            HSpacer {
            }
            Label {
                opacity: 0.7
                text: 'Filter by'
            }
            RowLayout {
                Layout.fillWidth: false
                visible: stack_layout.currentIndex === 0
                FilterButton {
                    text: qsTrId('id_account')
                    popup: AccountFilterPopup {
                        context: self.context
                        model: transaction_model
                    }
                }
                FilterButton {
                    text: qsTrId('id_asset')
                    popup: AssetFilterPopup {
                        context: self.context
                        model: transaction_model
                    }
                }
                VSeparator {
                }
                LinkButton {
                    enabled: !transaction_list_page.empty
                    text: qsTrId('id_export')
                    onClicked: transaction_model.exportToFile()
                }
            }
            RowLayout {
                Layout.fillWidth: false
                visible: stack_layout.currentIndex === 1
                FilterButton {
                    text: qsTrId('id_account')
                    popup: AccountFilterPopup {
                        context: self.context
                        model: address_model
                    }
                }
                FilterButton {
                    text: qsTrId('id_address')
                    popup: AddressFilterPopup {
                        context: self.context
                        model: address_model
                    }
                }
                VSeparator {
                }
                LinkButton {
                    enabled: !address_list_page.empty
                    text: qsTrId('id_export')
                    onClicked: address_model.exportToFile()
                }
            }
            RowLayout {
                Layout.fillWidth: false
                visible: stack_layout.currentIndex === 2
                FilterButton {
                    text: qsTrId('id_account')
                    popup: AccountFilterPopup {
                        context: self.context
                        model: coin_model
                    }
                }
                FilterButton {
                    text: qsTrId('id_asset')
                    popup: AssetFilterPopup {
                        context: self.context
                        model: coin_model
                    }
                }
            }
            Item {
                Layout.minimumWidth: 16
            }
        }
    }

    component VSeparator: Rectangle {
        Layout.leftMargin: 10
        Layout.rightMargin: 10
        color: '#FFFFFF'
        implicitHeight: 14
        implicitWidth: 1
        opacity: 0.7
    }

    component FilterButton: AbstractButton {
        required property Component popup
        property var popupItem: null
        id: button
        leftPadding: 12
        rightPadding: 12
        topPadding: 8
        bottomPadding: 8
        background: Rectangle {
            color: '#FFFFFF'
            radius: 4
            opacity: 0.2
            visible: button.hovered || button.popupItem
        }
        contentItem: RowLayout {
            spacing: 4
            opacity: 0.7
            Label {
                Layout.alignment: Qt.AlignCenter
                text: button.text
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/caret-down-white.svg'
            }
        }
        onClicked: {
            if (button.popupItem) return
            button.popupItem = button.popup.createObject(button)
            button.popupItem.closed.connect(() => { button.popupItem = null })
            button.popupItem.open()
        }
    }

    component TabButton2: AbstractButton {
        required property int index
        id: button
        checked: stack_layout.currentIndex === button.index
        background: Item {
            Rectangle {
                color: '#FFF'
                opacity: 0.2
                visible: button.hovered
            }
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 2
                color: '#00BCFF'
                visible: button.checked
            }
        }
        contentItem: Label {
            leftPadding: 24
            rightPadding: 24
            topPadding: 16
            bottomPadding: 16
            font.pixelSize: 14
            font.weight: 600
            text: button.text
        }
        onClicked: stack_layout.currentIndex = button.index
    }

    leftPadding: -32
    contentItem: SplitView {
        onResizingChanged: {
            if (!split_view.resizing) {
                if (accounts_container.width < 250) {
                    accounts_container.SplitView.preferredWidth = 0
                }
            }
        }
        id: split_view
        handle: Item {
            implicitWidth: 32
            implicitHeight: split_view.height
        }
        Item {
            SplitView.maximumWidth: self.width / 3
            SplitView.fillHeight: true
            Behavior on SplitView.preferredWidth {
                SmoothedAnimation {
                    velocity: 1000
                }
            }
            id: accounts_container
            clip: true
            TListView {
                anchors.right: parent.right
                height: parent.height
                width: Math.max(parent.width, 250) - 32
                model: account_list_model
                currentIndex: 0
                spacing: 5
                footer: Item {
                    height: 24
                }
                delegate: AccountDelegate {
                    id: delegate
                    highlighted: self.currentModel.filterAccounts.indexOf(delegate.account) >= 0
                    onAccountClicked: account => {
                        if (delegate.highlighted) {
                            self.currentModel.updateFilterAccounts(delegate.account, false)
                        } else {
                            self.currentModel.setFilterAccount(account)
                        }
                    }
                    onAccountArchived: account => {
                        self.currentModel.updateFilterAccounts(delegate.account, false)
                    }
                }
            }
        }
        StackLayout {
            SplitView.fillHeight: true
            SplitView.fillWidth: true
            id: stack_layout
            currentIndex: 0
            ListPage {
                id: transaction_list_page
                emptyText: `You don't have any transactions yet.`
                listHeader: ColumnLayout {
                    spacing: 4
                    width: ListView.view.width
                    Repeater {
                        id: payments_repeater
                        model: PaymentModel {
                            context: self.context
                        }
                        delegate: PaymentDelegate {
                            Layout.fillWidth: true
                        }
                    }
                    Item {
                        Layout.minimumHeight: 4
                        visible: payments_repeater.count > 0
                    }
                }
                model: TransactionModel {
                    id: transaction_model
                    context: self.context
                }
                delegate: TransactionDelegate {
                    id: delegate
                    context: self.context
                    leftPadding: 24
                    rightPadding: 24
                    topPadding: 12
                    bottomPadding: 12
                    width: ListView.view.width
                    background: Rectangle {
                        border.color: '#262626'
                        border.width: 1
                        color: Qt.lighter('#181818', delegate.enabled && delegate.hovered ? 1.2 : 1)
                        radius: 8
                    }
                    onClicked: self.transactionClicked(delegate.transaction)
                }
            }
            ListPage {
                id: address_list_page
                emptyText: 'Your wallet addresses will appear here once they are created.'
                model: AddressModel {
                    id: address_model
                    context: self.context
                }
                delegate: AddressDelegate {
                    id: delegate
                    leftPadding: 24
                    rightPadding: 24
                    topPadding: 12
                    bottomPadding: 12
                    background: Rectangle {
                        border.color: '#262626'
                        border.width: 1
                        color: Qt.lighter('#181818', delegate.enabled && delegate.hovered ? 1.2 : 1)
                        radius: 8
                    }
                    onClicked: self.addressClicked(delegate.address)
                }
            }
            ListPage {
                emptyText: `You don't have any coins yet.`
                model: CoinModel {
                    id: coin_model
                    context: self.context
                }
                delegate: OutputDelegate {
                    // highlighted: selection_model.selectedIndexes.indexOf(output_model.index(output_model.indexOf(output), 0))>-1
                    id: delegate
                    width: ListView.view.width
                    //onClicked: {
                        // selection_model.select(output_model.index(output_model.indexOf(delegate.output), 0), ItemSelectionModel.Toggle)
                    // }
                    leftPadding: 24
                    rightPadding: 24
                    topPadding: 12
                    bottomPadding: 12
                    background: Rectangle {
                        border.color: '#262626'
                        border.width: 1
                        color: Qt.lighter('#181818', delegate.enabled && delegate.hovered ? 1.2 : 1)
                        radius: 8
                    }
                }
            }
        }
    }

    component ListPage: Page {
        required property ContextModel model
        required property Component delegate
        required property string emptyText
        readonly property bool empty: list_view.count === 0
        property alias listHeader: list_view.header
        id: list_page
        background: null
        padding: 0
        spacing: 12
        header: TTextField {
            id: search_field
            leftPadding: 15 + left_layout.width + 15
            rightPadding: 15 + right_layout.width + 15
            RowLayout {
                id: left_layout
                anchors.leftMargin: 15
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                spacing: 12
                Image {
                    source: 'qrc:/svg2/search.svg'
                }
            }
            RowLayout {
                id: right_layout
                anchors.rightMargin: 15
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                spacing: 12
                Repeater {
                    model: list_page.model.filterAccounts
                    Label {
                        leftPadding: 8
                        rightPadding: 8
                        bottomPadding: 4
                        topPadding: 4
                        background: Rectangle {
                            radius: 4
                            color: UtilJS.networkColor(modelData.network)
                        }
                        font.weight: 600
                        text: UtilJS.accountName(modelData)
                    }
                }
                Item {
                    Layout.minimumWidth: 8
                    visible: list_page.model.filterAccounts.length > 0 && list_page.model.filterAssets.length > 0
                }
                Repeater {
                    model: list_page.model.filterAssets
                    AssetIcon {
                        size: 24
                        asset: modelData
                    }
                }
                Label {
                    leftPadding: 8
                    rightPadding: 8
                    bottomPadding: 4
                    topPadding: 4
                    background: Rectangle {
                        radius: 4
                        color: '#FFF'
                        opacity: 0.2
                    }
                    font.weight: 600
                    text: 'Has transactions'
                    visible: list_page.model.filterHasTransactions
                }
                Repeater {
                    model: list_page.model.filterTypes
                    Label {
                        leftPadding: 8
                        rightPadding: 8
                        bottomPadding: 4
                        topPadding: 4
                        background: Rectangle {
                            radius: 4
                            color: '#FFF'
                            opacity: 0.2
                        }
                        font.weight: 600
                        text: modelData.toUpperCase()
                    }
                }
                CircleButton {
                    focusPolicy: Qt.NoFocus
                    icon.source: 'qrc:/svg2/x-circle.svg'
                    visible: {
                        if (list_page.model.filterText.length > 0) return true
                        if (list_page.model.filterAccounts.length > 0) return true
                        if (list_page.model.filterAssets.length > 0) return true
                        if (list_page.model.filterTypes.length > 0) return true
                        if (list_page.model.filterHasTransactions) return true
                        return false
                    }
                    onClicked: {
                        list_page.model.clearFilters()
                        search_field.clear()
                    }
                }
            }
            Label {
                text: qsTrId('id_search')
                opacity: 0.6
                visible: search_field.text === ''
                anchors.left: parent.left
                anchors.leftMargin: search_field.leftPadding
                anchors.baseline: parent.baseline
            }
            onTextEdited: list_page.model.filterText = search_field.text
        }
        contentItem: TListView {
            id: list_view
            spacing: 4
            model: list_page.model
            footer: Item {
                height: 24
            }
            delegate: list_page.delegate
            Label {
                anchors.centerIn: list_view
                color: '#929292'
                font.pixelSize: 14
                text: list_page.emptyText
                visible: list_page.empty
            }
        }
    }

    component PaymentDelegate: ItemDelegate {
        required property Payment payment
        id: delegate
        focusPolicy: Qt.ClickFocus
        leftPadding: 24
        rightPadding: 24
        topPadding: 12
        bottomPadding: 12
        background: Rectangle {
            border.color: '#262626'
            border.width: 1
            color: Qt.lighter('#181818', delegate.enabled && delegate.hovered ? 1.2 : 1)
            radius: 8
        }
        spacing: 0
        contentItem: RowLayout {
            spacing: 10
            Image {
                Layout.alignment: Qt.AlignCenter
                source: `qrc:/svg2/tx-incoming.svg`
            }
            Label {
                Layout.fillWidth: true
                Layout.maximumWidth: 130
                color: '#FFF'
                font.pixelSize: 14
                font.weight: 600
                text: qsTrId('id_received')
            }
            Label {
                Layout.fillWidth: true
                Layout.maximumWidth: 130
                color: '#929292'
                text: delegate.payment.updatedAt.toLocaleString(locale.dateTimeFormat(Locale.LongFormat))
                font.pixelSize: 14
                font.weight: 400
                font.capitalization: Font.AllUppercase
                opacity: 0.6
            }
            AccountLabel {
                Layout.fillWidth: true
                Layout.maximumWidth: 150
                account: delegate.payment.address.account
            }
            HSpacer {
            }
            TransactionStatusBadge {
                confirmations: 0
                liquid: false
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: 150
                Label {
                    Layout.alignment: Qt.AlignRight
                    color: '#00BCFF'
                    font.pixelSize: 14
                    font.weight: 600
                    text: UtilJS.incognito(Settings.incognito, `${delegate.payment.data.destinationAmount} ${delegate.payment.data.destinationCurrencyCode}`)
                }
                Label {
                    Layout.alignment: Qt.AlignRight
                    color: '#929292'
                    font.pixelSize: 12
                    font.weight: 400
                    text: UtilJS.incognito(Settings.incognito, `${delegate.payment.data.sourceAmount} ${delegate.payment.data.sourceCurrencyCode}`)
                }
            }
        }
    }
}
