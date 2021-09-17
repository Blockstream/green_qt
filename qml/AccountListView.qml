import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

Page {
    required property Wallet wallet
    property Account currentAccount: account_list_view.currentItem ? account_list_view.currentItem.account : null
    signal clicked(Account account)

    id: self
    background: null
    spacing: constants.p1

    header: GHeader {
        Label {
            Layout.alignment: Qt.AlignVCenter
            text: qsTrId('Accounts')
            font.pixelSize: 20
            font.styleName: 'Bold'
            verticalAlignment: Label.AlignVCenter
        }
        HSpacer {
        }
        GButton {
            Layout.alignment: Qt.AlignVCenter
            text: '+'
            font.pixelSize: 14
            font.styleName: 'Medium'
            onClicked: create_account_dialog.createObject(window, { wallet }).open()
        }
    }
    contentItem: GListView {
        id: account_list_view
        model: AccountListModel {
            wallet: self.wallet
            filter: '!hidden'
        }
        clip: true
        spacing: 0
        delegate: Button {
            property Account account: modelData

            id: delegate
            focusPolicy: Qt.ClickFocus
            onClicked: {
                account_list_view.currentIndex = index
                self.clicked(account)
            }
            background: Rectangle {
                color: delegate.highlighted ? constants.c700 : delegate.hovered ? constants.c700 : constants.c800
                radius: 4
                border.width: 1
                border.color: delegate.highlighted ? constants.g500 : constants.c700
            }
            highlighted: account_list_view.currentIndex === index
            leftPadding: constants.p2
            rightPadding: constants.p2
            topPadding: constants.p2
            bottomPadding: constants.p3
            hoverEnabled: true
            width: ListView.view.contentWidth
            contentItem: ColumnLayout {
                spacing: 4
                RowLayout {
                    EditableLabel {
                        id: name_field
                        Layout.fillWidth: true
                        font.styleName: 'Medium'
                        font.pixelSize: 14
                        leftInset: -8
                        rightInset: -8
                        text: accountName(account)
                        enabled: !account.wallet.watchOnly && delegate.ListView.isCurrentItem && !delegate.account.wallet.locked
                        onEdited: {
                            if (enabled) {
                                account.rename(text, activeFocus)
                            }
                        }
                    }
                }

                RowLayout {
                    spacing: 10

                    Label {
                        text: formatAmount(account.balance)
                        font.pixelSize: 12
                        font.styleName: 'Regular'
                    }

                    Label {
                        font.pixelSize: 12
                        text: '≈ ' + formatFiat(account.balance)
                        font.styleName: 'Regular'
                    }

                    HSpacer {
                    }

                    AccountTypeBadge {
                        account: delegate.account
                    }
                }
            }
        }
    }
}
