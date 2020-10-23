import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

ListView {
    model: wallet.accounts

    delegate: ItemDelegate {
        property Account account: modelData

        onClicked: wallet.currentAccount = account
        highlighted: wallet.currentAccount === account
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
            SectionLabel {
                text: 'Managed Assets Account'
                visible: account.json.type === '2of2_no_recovery'
                anchors.right: parent.right
                anchors.rightMargin: 8
                font.pixelSize: 10
                padding: 8
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    color: '#2CCCBF'
                    opacity: 1
                    radius: height / 2
                    z: -1
                }
            }
            SectionLabel {
                text: qsTrId('id_2of3_account')
                visible: account.json.type === '2of3'
                anchors.right: parent.right
                anchors.rightMargin: 8
                font.pixelSize: 10
                padding: 8
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    color: 'white'
                    opacity: 0.2
                    radius: height / 2
                    z: -1
                }
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
                        enabled: !wallet.locked && account.balance > 0
                        icon.source: 'qrc:/svg/send.svg'
                        icon.width: 24
                        icon.height: 24
                        text: qsTrId('id_send')
                        onClicked: send_dialog.createObject(stack_view, { account }).open()
                    }

                    Button {
                        flat: true
                        enabled: !wallet.locked
                        icon.source: 'qrc:/svg/receive.svg'
                        icon.width: 24
                        icon.height: 24
                        text: qsTrId('id_receive')
                        onClicked: receive_dialog.createObject(stack_view).open()
                    }
                }
            }
        }
    }

    ScrollIndicator.vertical: ScrollIndicator { }

    ScrollShadow {}
}
