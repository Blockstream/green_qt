import Blockstream.Green
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

GPane {
    required property Account account

    id: self

    contentItem: TListView {
        id: list_view
        model: self.account.balances
        spacing: 8
        delegate: AssetDelegate {
            balance: modelData
            width: ListView.view.contentWidth
            onClicked: if (hasDetails) balance_dialog.createObject(window, { balance }).open()
        }
    }
}
