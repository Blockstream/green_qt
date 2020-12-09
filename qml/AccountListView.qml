import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

ListView {
    id: account_list_view
    model: wallet.accounts
    property Account currentAccount: currentItem ? currentItem.account : null
    signal clicked(Account account)
    delegate: ItemDelegate {
        property Account account: modelData

        onClicked: {
            account_list_view.currentIndex = index
            account_list_view.clicked(account)
        }
        highlighted: currentIndex === index
        leftPadding: 16
        rightPadding: 8
        width: ListView.view.width

        contentItem: Column {
            spacing: 0

            SectionLabel {
                elide: Text.ElideRight
                font.capitalization: Font.MixedCase
                text: accountName(account)
                width: parent.width
                ToolTip.text: accountName(account)
                ToolTip.visible: truncated && hovered
            }
            SectionLabel {
                text: qsTrId('id_managed_assets')
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
                    MouseArea {
                        hoverEnabled: account.wallet.network.liquid && account.balance === 0
                        width: send_button.width
                        height: send_button.height
                        Button {
                            id: send_button
                            flat: true
                            enabled: !wallet.locked && account.balance > 0
                            icon.source: 'qrc:/svg/send.svg'
                            icon.width: 24
                            icon.height: 24
                            text: qsTrId('id_send')
                            onClicked: send_dialog.createObject(window, { account }).open()
                            ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                            ToolTip.text: qsTrId('id_insufficient_lbtc_to_send_a')
                            ToolTip.visible: parent.containsMouse
                        }
                    }

                    Button {
                        flat: true
                        enabled: !wallet.locked
                        icon.source: 'qrc:/svg/receive.svg'
                        icon.width: 24
                        icon.height: 24
                        text: qsTrId('id_receive')
                        onClicked: receive_dialog.createObject(window).open()
                    }
                }
            }
        }
    }

    ScrollIndicator.vertical: ScrollIndicator { }
}
