import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

import "analytics.js" as AnalyticsJS

SwipeView {
    required property Wallet wallet
    property Account currentAccount: {
        const view = showArchived ? archive_list_view : account_list_view
        return view.currentItem ? view.currentItem.account : null
    }
    property bool showArchived: false

    function openCreateDialog() {
        const dialog = create_account_dialog.createObject(window, { wallet })
        dialog.accepted.connect(() => {
            // automatically select the last account since it is the newly created account
            // if account ordering is added then if should determine the correct index
            account_list_view.currentIndex = account_list_view.count - 1;
        })
        dialog.open()
    }

    Connections {
        target: archive_list_view
        function onCountChanged() {
            if (showArchived && archive_list_view.count === 0) showArchived = false
        }
    }

    id: self
    interactive: false
    currentIndex: showArchived ? 1 : 0
    clip: true
    spacing: constants.p1

    Page {
        background: null
        header: GHeader {
            Label {
                Layout.alignment: Qt.AlignVCenter
                text: qsTrId('id_accounts')
                font.pixelSize: 20
                font.styleName: 'Bold'
                verticalAlignment: Label.AlignVCenter
            }
            HSpacer {
            }
            GButton {
                Layout.alignment: Qt.AlignVCenter
                icon.source: 'qrc:/svg/kebab.svg'
                icon.height: 14
                icon.width: 14
                enabled: !menu.opened
                Menu {
                    id: menu
                    width: 300
                    MenuItem {
                        enabled: !wallet.watchOnly
                        text: qsTrId('id_add_new_account')
                        onTriggered: openCreateDialog()
                    }
                    MenuItem {
                        enabled: !showArchived && archive_list_view.count > 0
                        text: qsTrId('id_view_archived_accounts_d').arg(archive_list_view.count)
                        onTriggered: showArchived = !showArchived
                    }
                }
                onClicked: menu.popup()
            }
        }
        contentItem: GListView {
            id: account_list_view
            clip: true
            spacing: 0
            model: AccountListModel {
                wallet: self.wallet
                filter: '!hidden'
            }
            delegate: AccountDelegate {
            }
        }
    }

    Page {
        background: null
        header: RowLayout {
            spacing: constants.s2
            GToolButton {
                icon.source: 'qrc:/svg/arrow_left.svg'
                Layout.alignment: Qt.AlignVCenter
                onClicked: showArchived = false
            }
            Label {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                text: qsTrId('id_archived_accounts')
                font.pixelSize: 20
                font.styleName: 'Bold'
                verticalAlignment: Label.AlignVCenter
            }
        }
        contentItem: GListView {
            id: archive_list_view
            clip: true
            spacing: 0
            model: AccountListModel {
                wallet: self.wallet
                filter: 'hidden'
            }
            delegate: AccountDelegate {
            }
        }
        AnalyticsView {
            active: self.showArchived
            name: 'ArchivedAccounts'
            segmentation: AnalyticsJS.segmentationSession(self.wallet)
        }
    }
}
