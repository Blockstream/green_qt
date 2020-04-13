import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

ListView {
    spacing: 8
    model: wallet.accounts

    delegate: ItemDelegate {
        property Account account: modelData

        onClicked: wallet_view.currentAccount = account
        background.opacity: 0.4
        highlighted: wallet_view.account === account
        leftPadding: 16
        rightPadding: 8
        width: ListView.view.width

        contentItem: Column {
            spacing: 0

            SectionLabel {
                elide: Text.ElideRight
                font.capitalization: Font.MixedCase
                text: account.name
                width: parent.width
                ToolTip.text: account.name
                ToolTip.visible: truncated && hovered
            }
            Item { height: 8; width: 1 }
            Row {
                spacing: 10
                Label {
                    text: formatAmount(account.balance)
                    font.pixelSize: 16
                }
                Label {
                    anchors.bottom: parent.bottom
                    text: '≈ ' + formatFiat(account.balance)
                }
            }
            Item { height: 8; width: 1 }
            Collapsible {
                collapsed: !highlighted
                anchors.right: parent.right
                Row {
                    spacing: 8
                    Button {
                        flat: true
                        enabled: !wallet.locked
                        icon.source: '/svg/send.svg'
                        icon.width: 24
                        icon.height: 24
                        text: qsTr('id_send')
                        onClicked: send_dialog.createObject(stack_view, { account }).open()
                    }

                    Button {
                        flat: true
                        enabled: !wallet.locked
                        icon.source: '/svg/receive.svg'
                        icon.width: 24
                        icon.height: 24
                        text: qsTr('id_receive')
                        onClicked: receive_dialog.createObject(stack_view).open()
                    }
                }
            }
        }
    }

    ScrollIndicator.vertical: ScrollIndicator { }

    ScrollShadow {}
}
