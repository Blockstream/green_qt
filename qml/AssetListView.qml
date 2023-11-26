import Blockstream.Green
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

GPane {
    required property Account account

    id: self
    background: Rectangle {
        color: '#161921'
        border.width: 1
        border.color: '#1F222A'
        radius: 4
    }
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
