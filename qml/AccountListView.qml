import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import "analytics.js" as AnalyticsJS

TListView {
    required property Context context
    property Account currentAccount: self.currentItem?.account ?? null

    Connections {
        target: self.context
        function onAccountsChanged() {
            // automatically select the last account since it is the newly created account
            // if account ordering is added then if should determine the correct index
            // TODO:
            self.currentIndex = account_list_view.count - 1;
        }
    }

    id: self
    model: account_list_model
    spacing: 3
    delegate: AccountDelegate {
    }
}
