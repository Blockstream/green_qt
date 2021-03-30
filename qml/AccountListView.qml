import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

ListView {
    id: account_list_view
    model: wallet.accounts
    property Account currentAccount: currentItem ? currentItem.account : null
    signal clicked(Account account)
    spacing: 8
    delegate: ItemDelegate {
        id: delegate
        property Account account: modelData

        onClicked: {
            account_list_view.currentIndex = index
            account_list_view.clicked(account)
        }
        background: Rectangle {
            color: delegate.highlighted ? constants.c500 : constants.c700
            radius: 8
        }

        highlighted: currentIndex === index
        leftPadding: 16
        rightPadding: 16
        topPadding: 16
        bottomPadding: 16

        width: ListView.view.width-16

        contentItem: ColumnLayout {
            spacing: 8
            Label {
                text: qsTrId('id_managed_assets')
                visible: account.json.type === '2of2_no_recovery'
                font.pixelSize: 12
                font.capitalization: Font.AllUppercase
                leftPadding: 8
                rightPadding: 8
                topPadding: 4
                bottomPadding: 4
                opacity: 1
                color: 'white'
                background: Rectangle {
                    color: '#080b0e'
                    opacity: 0.2
                    radius: 4
                }
            }
            Label {
                text: qsTrId('id_2of3_account')
                visible: account.json.type === '2of3'
                font.pixelSize: 12
                font.capitalization: Font.AllUppercase
                leftPadding: 8
                rightPadding: 8
                topPadding: 4
                bottomPadding: 4
                color: 'white'
                background: Rectangle {
                    color: '#080b0e'
                    opacity: 0.2
                    radius: 4
                }
            }
            Label {
                Layout.fillWidth: true
                font.styleName: 'Medium'
                font.pixelSize: 18
                elide: Text.ElideRight
                text: accountName(account)
                ToolTip.text: accountName(account)
                ToolTip.visible: truncated && hovered
            }
            RowLayout {
                spacing: 10
                Label {
                    text: formatAmount(account.balance)
                    font.pixelSize: 14
                    font.styleName: 'Regular'
                }
                Label {
                    font.pixelSize: 14
                    text: '≈ ' + formatFiat(account.balance)
                    font.styleName: 'Regular'
                }
            }
            Collapsible {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignRight
                collapsed: !highlighted
                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 8
                    Button {
                        Layout.fillWidth: true
                        id: send_button
                        flat: true
                        enabled: !wallet.locked && account.balance > 0
                        icon.source: 'qrc:/svg/send.svg'
                        icon.width: 24
                        icon.height: 24
                        hoverEnabled: true
                        text: qsTrId('id_send')
                        onClicked: send_dialog.createObject(window, { account: delegate.account }).open()
                        ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                        ToolTip.text: qsTrId('id_insufficient_lbtc_to_send_a')
                        ToolTip.visible: hovered && !enabled
                    }
                    Button {
                        Layout.fillWidth: true
                        flat: true
                        enabled: !wallet.locked
                        icon.source: 'qrc:/svg/receive.svg'
                        icon.width: 24
                        icon.height: 24
                        text: qsTrId('id_receive')
                        onClicked: receive_dialog.createObject(window, { account: delegate.account }).open()
                    }
                }
            }
        }
    }

    ScrollIndicator.vertical: ScrollIndicator { }
}
