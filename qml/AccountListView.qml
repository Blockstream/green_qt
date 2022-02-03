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
            onClicked: {
                const dialog = create_account_dialog.createObject(window, { wallet })
                dialog.accepted.connect(() => {
                    // automatically select the last account since it is the newly created account
                    // if account ordering is added then if should determine the correct index
                    account_list_view.currentIndex = account_list_view.count - 1;
                })
                dialog.open()
            }
        }
    }
    contentItem: SwipeView {
        interactive: false
        clip: true
        GListView {
            id: account_list_view
            model: AccountListModel {
                wallet: self.wallet
                filter: '!hidden'
            }
            spacing: 0
            delegate: AccountDelegate {
            }
        }
    }

    component AccountDelegate: Button {
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
            spacing: 8
            RowLayout {
                spacing: 16
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
                AccountTypeBadge {
                    account: delegate.account
                }
            }
            RowLayout {
                RowLayout {
                    spacing: 2
                    Repeater {
                        model: {
                            const assets = []
                            let without_icon = false
                            for (let i = 0; i < account.balances.length; i++) {
                                const { amount, asset }= account.balances[i]
                                if (amount === 0) continue;
                                if (asset.icon || !without_icon) assets.push(asset)
                                without_icon = !asset.icon
                            }
                            return assets
                        }
                        AssetIcon {
                            asset: modelData
                            size: 16
                        }
                    }
                }
                HSpacer {
                }
                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: 10
                    Label {
                        text: formatAmount(account.balance)
                        font.pixelSize: 14
                        font.styleName: 'Regular'
                    }
                    Label {
                        text: '≈ ' + formatFiat(account.balance)
                        font.pixelSize: 14
                        font.styleName: 'Regular'
                    }
                }
            }
        }
    }
}
