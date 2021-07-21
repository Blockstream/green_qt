import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3

Page {
    required property Account account
    property alias interactive: list_view.interactive
    property alias label: label
    property alias list: list_view
    property alias maxRowCount: transaction_list_filter.maxRowCount
    property bool hasExport: true

    id: self
    title: qsTrId('id_transactions')
    background: null
    spacing: constants.p1
    header: GHeader {
        Label {
            Layout.alignment: Qt.AlignVCenter
            id: label
            text: self.title
            font.pixelSize: 20
            font.styleName: 'Bold'
        }
        HSpacer {
        }
        GSearchField {
            Layout.alignment: Qt.AlignVCenter
            visible: self.hasExport
            id: search_field
        }
        GButton {
            Layout.alignment: Qt.AlignVCenter
            text: qsTrId('Export')
            visible: self.hasExport
            enabled: self.account.wallet.ready && !list_view.model.fetching && list_view.count > 0
            onClicked: export_transactions_popup.createObject(window, { account: self.account }).open()
            ToolTip.text: qsTrId('id_export_transactions_to_csv_file')
        }
    }
    contentItem: GListView {
        id: list_view
        clip: true
        spacing: 8
        model: TransactionFilterProxyModel {
            id: transaction_list_filter
            filter: search_field.text
            model: TransactionListModel {
                id: transaction_list_model
                account: self.account
            }
        }
        delegate: TransactionDelegate {
            hoverEnabled: false
            width: list_view.width
            onClicked: transaction_dialog.createObject(window, { transaction }).open()
        }
        ScrollIndicator.vertical: ScrollIndicator { }

        BusyIndicator {
            width: 32
            height: 32
            running: transaction_list_model.fetching
            anchors.margins: 8
            Layout.alignment: Qt.AlignHCenter
            visible: running ? 1 : 0
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Label {
            visible: !list_view.model.fetching && list_view.count === 0
            anchors.centerIn: parent
            color: 'white'
            text: qsTrId('id_your_transactions_will_be_shown')
        }
    }

    Component {
        id: transaction_dialog
        TransactionView {
        }
    }
}
