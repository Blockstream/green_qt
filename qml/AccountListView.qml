import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import "analytics.js" as AnalyticsJS

GPane {
    property real contentY: Math.max(archive_list_view.contentY + archive_list_view.headerItem.height, account_list_view.contentY)
    required property Context context
    property Account currentAccount: {
        const view = showArchived ? archive_list_view : account_list_view
        return view.currentItem ? view.currentItem.account : null
    }
    readonly property bool showArchived: navigation.param?.archive ?? false

    Connections {
        target: archive_list_view
        function onCountChanged() {
            if (showArchived && archive_list_view.count === 0) navigation.set({ archive: false })
        }
    }

    Connections {
        target: self.context
        function onAccountsChanged() {
            // automatically select the last account since it is the newly created account
            // if account ordering is added then if should determine the correct index
            account_list_view.currentIndex = account_list_view.count - 1;
        }
    }

    id: self

//    Menu {
//        id: menu
//        width: 300
//        MenuItem {
//            onTriggered: openCreateDialog()
//        }
//        MenuItem {
//            enabled: !showArchived && archive_list_view.count > 0
//            text: qsTrId('id_view_archived_accounts_d').arg(archive_list_view.count)
//            onTriggered: showArchived = !showArchived
//        }
//    }
//    onClicked: menu.popup()
    contentItem: StackLayout {
        currentIndex: showArchived ? 1 : 0
        TListView {
            id: account_list_view
            model: account_list_model
        }

        TListView {
            id: archive_list_view
            model: archive_list_model
            header: GPane {
                bottomPadding: constants.p3
                width: archive_list_view.contentWidth
                contentItem: RowLayout {
                    Label {
                        Layout.fillWidth: true
                        font.pixelSize: 16
                        font.styleName: 'Bold'
                        text: qsTrId('id_archived_accounts')
                    }
                    HSpacer {
                    }
                    GButton {
                        Layout.alignment: Qt.AlignVCenter
                        text: qsTrId('id_back')
                        onClicked: navigation.set({ archive: false })
                    }
                }
            }
            AnalyticsView {
                active: self.showArchived
                name: 'ArchivedAccounts'
                segmentation: AnalyticsJS.segmentationSession(self.context.wallet)
            }
        }
    }

    component TListView: ListView {
        contentWidth: width
        spacing: 8
        displayMarginBeginning: 200
        displayMarginEnd: 200
        delegate: Component {
            AccountDelegate {
            }
        }
        ScrollIndicator.vertical: ScrollIndicator { }
    }
}
