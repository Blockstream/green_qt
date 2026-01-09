import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

WalletDrawer {
    id: self
    contentItem: GStackView {
        initialItem: StackViewPage {
            title: qsTrId('id_archived_accounts')
            rightItem: CloseButton {
                onClicked: self.close()
            }
            contentItem: TListView {
                id: list_view
                onCountChanged: if (count === 0) self.close()
                currentIndex: 0
                spacing: 5
                model: UtilJS.archivedAccounts(self.context)
                delegate: AccountDelegate {
                    required property var modelData
                    id: delegate
                    account: delegate.modelData
                    onClicked: list_view.currentIndex = delegate.index
                    highlighted: list_view.currentIndex === delegate.index
                }
            }
        }
    }
}
