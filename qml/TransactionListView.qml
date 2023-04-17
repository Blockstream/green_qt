import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

GPane {
    required property Account account
    readonly property real contentY: list_view.contentY + list_view.headerItem.height
    readonly property bool empty: !transaction_list_model.dispatcher.busy && list_view.count === 0

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

    background: Label {
        visible: self.empty
        text: qsTrId('id_your_transactions_will_be_shown')
        horizontalAlignment: Label.AlignHCenter
        verticalAlignment: Label.AlignVCenter
    }

    contentItem: TListView {
        id: list_view
        spacing: 8
        header: THeader {
            width: list_view.contentWidth
        }

        model: TransactionFilterProxyModel {
            filter: list_view.headerItem.searchText
            model: transaction_list_model
        }

        delegate: TransactionDelegate {
            width: ListView.view.contentWidth
            account: self.account
            context: self.account.context
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

    component THeader: GPane {
        property alias searchText: search_field.text
        bottomPadding: constants.p3
        width: list_view.contentWidth
        contentItem: RowLayout {
            GSearchField {
                id: search_field
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.maximumWidth: 300
            }
            HSpacer {
            }
            GButton {
                Layout.alignment: Qt.AlignVCenter
                text: qsTrId('Export')
                enabled: self.account.context && !transaction_list_model.dispatcher.busy && list_view.count > 0
                onClicked: export_transactions_popup.createObject(window, { account: self.account }).open()
                ToolTip.text: qsTrId('id_export_transactions_to_csv_file')
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
