import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    signal transactionClicked(Transaction transaction)
    required property Account account
    readonly property real contentY: list_view.contentY
    readonly property bool empty: list_view.count === 0
    property bool search: false
    id: self
    padding: 0
    focusPolicy: Qt.ClickFocus
    header: Collapsible {
        id: collapsible
        collapsed: !self.search
        animationVelocity: 300
        Pane {
            width: collapsible.width
            background: null
            padding: 20
            contentItem: RowLayout {
                spacing: 20
                SearchField {
                    Layout.fillWidth: true
                    id: search_field
                }
                LinkButton {
                    text: qsTrId('id_cancel')
                    onClicked: {
                        search_field.clear()
                        self.search = false
                    }
                }
            }
        }
    }
    background: Rectangle {
        color: '#161921'
        border.width: 1
        border.color: '#1F222A'
        radius: 4
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 20
            visible: !self.search & self.empty
            Image {
                Layout.preferredWidth: 350
                Layout.preferredHeight: 200
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/png/no_transactions.png'
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                font.pixelSize: 14
                font.weight: 600
                text: 'You don’t have any transactions in this wallet yet'
            }
        }
    }

    contentItem: TListView {
        id: list_view
        bottomMargin: 120
        spacing: -1
        model: TransactionFilterProxyModel {
            filter: search_field.text
            model: transaction_list_model
        }
        delegate: TransactionDelegate {
            width: ListView.view.width
            account: self.account
            context: self.account.context
            onTransactionClicked: (transaction) => self.transactionClicked(transaction)
        }
    }

    RowLayout {
        parent: toolbarItem
        visible: self.visible
        spacing: 10
        LinkButton {
            font.pixelSize: 16
            text: qsTrId('Export')
            enabled: self.account.context && list_view.count > 0
            onClicked: {
                const dialog = export_transactions_dialog.createObject(self, {
                    account: self.account,
                })
                dialog.open()
            }
        }
        Rectangle {
            Layout.alignment: Qt.AlignCenter
            Layout.preferredHeight: 24
            Layout.preferredWidth: 1
            color: '#FFF'
            opacity: 0.2
        }
        CircleButton {
            icon.source: 'qrc:/svg2/search_green.svg'
            enabled: !self.search && self.account.context && list_view.count > 0
            onClicked: {
                self.search = true
                search_field.forceActiveFocus()
            }
        }
    }

    Component {
        id: export_transactions_dialog
        ExportTransactionsDialog {
        }
    }
}
