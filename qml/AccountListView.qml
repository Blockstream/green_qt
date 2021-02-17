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
    BusyIndicator {
        width: 32
        height: 32
        opacity: accounts_list.count === 0 ? 1 : 0
        Behavior on opacity { OpacityAnimator {} }
        running: accounts_list.count === 0
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.margins: 8
    }
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
        topPadding: 8
        bottomPadding: 8

        width: ListView.view.width

        contentItem: ColumnLayout {
            spacing: 8
            RowLayout {
                Label {
                    Layout.fillWidth: true
                    font.styleName: 'Regular'
                    font.pixelSize: 16
                    elide: Text.ElideRight
                    text: accountName(account)
                    ToolTip.text: accountName(account)
                    ToolTip.visible: truncated && hovered
                }
                Label {
                    font.capitalization: Font.AllUppercase
                    text: qsTrId('id_managed_assets')
                    visible: account.json.type === '2of2_no_recovery'
                    font.pixelSize: 10
                    padding: 8
                    opacity: 1
                    color: constants.c700
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        color: '#2CCCBF'
                        opacity: 1
                        radius: height / 2
                        z: -1
                    }
                }
                Label {
                    text: qsTrId('id_2of3_account')
                    visible: account.json.type === '2of3'
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
            }
            RowLayout {
                spacing: 10
                Label {
                    text: formatAmount(account.balance)
                    font.pixelSize: 16
                }
                Label {
                    text: '≈ ' + formatFiat(account.balance)
                }
            }
            Collapsible {
                Layout.alignment: Qt.AlignRight
                collapsed: !highlighted
                Row {
                    spacing: 8
//                    MouseArea {
//                        hoverEnabled: account.wallet.network.liquid && account.balance === 0
//                        width: send_button.width
//                        height: send_button.height
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
                        ToolTip.visible: hovered && !enabled
                    }
//                    }

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
