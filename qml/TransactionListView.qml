import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3

ListView {
    id: list_view
    required property Account account
    signal clicked(Transaction transaction)
    clip: true
    spacing: 8
    model: TransactionListModel {
        account: list_view.account
    }

    delegate: TransactionDelegate {
        hoverEnabled: false
        width: list_view.width
        onClicked: list_view.clicked(transaction)
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
        running: model.fetching
        anchors.margins: 8
        Layout.alignment: Qt.AlignHCenter
        opacity: model.fetching ? 1 : 0
        Behavior on opacity { OpacityAnimator {} }
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
    }
}
