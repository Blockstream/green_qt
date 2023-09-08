import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

GPane {
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

    background: Label {
        visible: self.empty
        text: qsTrId('id_your_transactions_will_be_shown')
        horizontalAlignment: Label.AlignHCenter
        verticalAlignment: Label.AlignVCenter
    }

    contentItem: TListView {
        id: list_view
        spacing: 8
        model: TransactionFilterProxyModel {
            filter: search_field.text
            model: transaction_list_model
        }

        delegate: TransactionDelegate {
            width: ListView.view.contentWidth
            account: self.account
            context: self.account.context
        }

//        section.property: "date"
//        section.criteria: ViewSection.FullString
//        section.delegate: sectionHeading
//        section.labelPositioning: ViewSection.InlineLabels

        // TODO
        // refreshGesture: true
        // refreshText: qsTrId('id_loading_transactions')
        // onRefreshTriggered: transaction_list_model.reload()
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
            onClicked: export_transactions_popup.createObject(window, { account: self.account }).open()
            ToolTip.text: qsTrId('id_export_transactions_to_csv_file')
        }
    }
}
