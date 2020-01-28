import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

ListView {
    spacing: 8
    model: wallet.accounts

    delegate: ItemDelegate {
        property Account account: modelData

        onClicked: ListView.view.currentIndex = index
        background.opacity: 0.4
        highlighted: ListView.isCurrentItem
        leftPadding: 16
        rightPadding: 8
        width: ListView.view.width

        contentItem: Column {
            spacing: 8

            Label {
                color: 'gray'
                elide: Text.ElideRight
                font.pixelSize: 16
                text: account.name
                width: parent.width
                ToolTip.text: account.name
                ToolTip.visible: truncated && hovered
            }

            Row {
                spacing: 10
                Label {
                    text: formatAmount(account.balance)
                    font.pixelSize: 16
                }
                Label {
                    anchors.bottom: parent.bottom
                    text: formatFiat(account.balance)
                }
            }

            Row {
                spacing: 8
                visible: highlighted
                anchors.right: parent.right

                FlatButton {
                    icon.source: 'assets/svg/send.svg'
                    icon.width: 24
                    icon.height: 24
                    text: qsTr('id_send')
                    onClicked: send_dialog.createObject(stack_view, { account }).open()
                }

                FlatButton {
                    icon.source: 'assets/svg/receive.svg'
                    icon.width: 24
                    icon.height: 24
                    text: qsTr('id_receive')
                    onClicked: receive_dialog.createObject(stack_view).open()
                }
            }
        }
    }

    ScrollIndicator.vertical: ScrollIndicator { }
}
