import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3

Page {
    required property Account account
    property alias interactive: list_view.interactive
    property alias label: label
    property bool hasExport: true

    id: self
    background: null
    spacing: constants.p1
    header: RowLayout {
        Label {
            id: label
            Layout.fillWidth: true
            text: qsTrId('id_transactions')
            font.pixelSize: 22
            font.styleName: "Bold"
        }
        HSpacer {
        }
        ToolButton {
            visible: self.hasExport
            enabled: self.account.wallet.ready && !list_view.model.fetching && list_view.count > 0
            icon.source: "qrc:/svg/export.svg"
            onClicked: export_transactions_popup.createObject(window, { account: self.account }).open()
        }
    }
    contentItem: ListView {
        id: list_view
        clip: true
        spacing: 8
        model: TransactionListModel {
            account: self.account
        }
        delegate: TransactionDelegate {
            hoverEnabled: false
            width: list_view.width
            onClicked: transaction_dialog.createObject(window, { transaction }).open()
        }
        ScrollIndicator.vertical: ScrollIndicator { }

        MouseArea {
            anchors.fill: parent
            onClicked: parent.forceActiveFocus(Qt.MouseFocusReason)
            z: -1
        }

        BusyIndicator {
            width: 32
            height: 32
            running: list_view.model.fetching
            anchors.margins: 8
            Layout.alignment: Qt.AlignHCenter
            opacity: list_view.model.fetching ? 1 : 0
            Behavior on opacity { OpacityAnimator {} }
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Label {
            visible: !list_view.model.fetching && list_view.count === 0
            anchors.centerIn: parent
            color: 'white'
            text: qsTrId("No transactions available")
        }
    }

    Component {
        id: transaction_dialog
        TransactionView {
        }
    }
}
