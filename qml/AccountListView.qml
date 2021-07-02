import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

Page {
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
        model: wallet.accounts
        clip: true
        spacing: 8
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
            width: ListView.view.width
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

                    Label {
                        text: qsTrId('Legacy')
                        visible: account.type === 'p2sh-p2wpkh'
                        font.pixelSize: 10
                        font.capitalization: Font.AllUppercase
                        leftPadding: 8
                        rightPadding: 8
                        topPadding: 4
                        bottomPadding: 4
                        opacity: 1
                        color: 'white'
                        background: Rectangle {
                            color: constants.c400
                            radius: 4
                        }
                    }

                    Label {
                        text: qsTrId('Segwit')
                        visible: account.type === 'p2wpkh'
                        font.pixelSize: 10
                        font.capitalization: Font.AllUppercase
                        leftPadding: 8
                        rightPadding: 8
                        topPadding: 4
                        bottomPadding: 4
                        opacity: 1
                        color: 'white'
                        background: Rectangle {
                            color: constants.c400
                            radius: 4
                        }
                    }

                    Label {
                        text: qsTrId('id_amp_account')
                        visible: account.type === '2of2_no_recovery'
                        font.pixelSize: 10
                        font.capitalization: Font.AllUppercase
                        leftPadding: 8
                        rightPadding: 8
                        topPadding: 4
                        bottomPadding: 4
                        opacity: 1
                        color: 'white'
                        background: Rectangle {
                            color: constants.c400
                            radius: 4
                        }
                    }

                    Label {
                        text: qsTrId('id_2of3_account')
                        visible: account.type === '2of3'
                        font.pixelSize: 10
                        font.capitalization: Font.AllUppercase
                        leftPadding: 8
                        rightPadding: 8
                        topPadding: 4
                        bottomPadding: 4
                        color: 'white'
                        background: Rectangle {
                            color: constants.c400
                            radius: 4
                        }
                    }
                }
            }
        }
        ScrollIndicator.vertical: ScrollIndicator {
            parent: account_list_view.parent
            anchors.top: account_list_view.top
            anchors.left: account_list_view.right
            anchors.leftMargin: 8
            anchors.bottom: account_list_view.bottom
        }
    }
}
