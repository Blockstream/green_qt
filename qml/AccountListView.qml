import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import "analytics.js" as AnalyticsJS

GPane {
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

    contentItem: StackLayout {
        currentIndex: showArchived ? 1 : 0
        AListView {
            id: account_list_view
            model: account_list_model
        }

        AListView {
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
                segmentation: AnalyticsJS.segmentationSession(self.context?.wallet)
            }
        }
    }

    component AListView: TListView {
        spacing: 3
        delegate: Component {
            AccountDelegate {
            }
        }
    }
}
