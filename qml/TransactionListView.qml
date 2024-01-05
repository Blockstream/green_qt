import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

GPane {
    signal transactionClicked(Transaction transaction)
    required property Account account
    readonly property real contentY: list_view.contentY
    readonly property bool empty: list_view.count === 0

    id: self

    Component {
        id: sectionHeading
        Label {
            required property string section
            topPadding: 0
            bottomPadding: 8
            leftPadding: constants.p3
            text: section
            opacity: 0.5
            font.bold: true
            font.pixelSize: 12
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
            visible: self.empty
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
        spacing: 0
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
        spacing: 8
        GSearchField {
            id: search_field
        }
        GButton {
            text: qsTrId('Export')
            enabled: self.account?.context && list_view.count > 0
            onClicked: export_transactions_dialog.createObject(self, { account: self.account }).open()
        }
    }

    Component {
        id: export_transactions_dialog
        ExportTransactionsDialog {
        }
    }
}
