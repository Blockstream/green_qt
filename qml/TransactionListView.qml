import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

GPane {
    property real contentY: list_view.contentY //+ list_view.headerItem.height
    required property Account account
    property alias interactive: list_view.interactive
    property alias list: list_view
    property bool hasExport: true

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

    contentItem: TListView {
        id: list_view
        spacing: 8
//        header: THeader {
//            width: list_view.contentWidth
//            height: 40
//        }

        model: TransactionFilterProxyModel {
//            filter: list_view.headerItem.searchText
            model: transaction_list_model
        }

        delegate: TransactionDelegate {
            width: ListView.view.contentWidth
            account: self.account
            context: self.account.context
            onClicked: transaction_dialog.createObject(window, { transaction }).open()
        }
        section.property: "date"
        section.criteria: ViewSection.FullString
        section.delegate: sectionHeading
        section.labelPositioning: ViewSection.InlineLabels // + ViewSection.CurrentLabelAtStart
        // TODO
        // refreshGesture: true
        // refreshText: qsTrId('id_loading_transactions')
        // onRefreshTriggered: transaction_list_model.reload()
        BusyIndicator {
            width: 32
            height: 32
            running: transaction_list_model.dispatcher.busy
            anchors.margins: 8
            Layout.alignment: Qt.AlignHCenter
            visible: running ? 1 : 0
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Label {
            visible: !transaction_list_model.dispatcher.busy && list_view.count === 0
            anchors.top: parent.top
            anchors.left: parent.left
            color: 'white'
            text: qsTrId('id_your_transactions_will_be_shown')
        }
    }

    Component {
        id: transaction_dialog
        TransactionView {
        }
    }

    Component {
        id: export_transactions_popup
        Popup {
            required property Account account
            id: dialog
            anchors.centerIn: Overlay.overlay
            closePolicy: Popup.NoAutoClose
            modal: true
            Overlay.modal: Rectangle {
                color: "#70000000"
            }
            onClosed: destroy()
            onOpened: controller.save()
            ExportTransactionsController {
                id: controller
                context: dialog.account.context
                account: dialog.account
                onSaved: dialog.close()
            }
            BusyIndicator {}
        }
    }

    component THeader: Item {
        property alias searchText: search_field.text
        GPane {
            width: list_view.contentWidth
            contentItem: RowLayout {
                HSpacer {
                }
                GSearchField {
                    id: search_field
                    Layout.alignment: Qt.AlignVCenter
                    visible: self.hasExport
                }
                GButton {
                    Layout.alignment: Qt.AlignVCenter
                    text: qsTrId('Export')
                    visible: self.hasExport
                    enabled: self.account.context && !transaction_list_model.dispatcher.busy && list_view.count > 0
                    onClicked: export_transactions_popup.createObject(window, { account: self.account }).open()
                    ToolTip.text: qsTrId('id_export_transactions_to_csv_file')
                }
            }
        }
    }

    component TListView: ListView {
        ScrollIndicator.vertical: ScrollIndicator { }
        contentWidth: width
        displayMarginBeginning: 300
        displayMarginEnd: 100
    }
}
