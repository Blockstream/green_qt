import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

GPane {
    signal signMessage(Address address)
    signal addressClicked(Address address)
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
        spacing: 0
        model: AddressListModel {
            account: self.account
            filter: search_field.text
        }
        delegate: AddressDelegate {
            width: ListView.view.width
            onAddressClicked: (address) => self.addressClicked(address)
        }
    }

    Component {
        id: export_addresses_dialog
        ExportAddressesDialog {
        }
    }

    RowLayout {
        spacing: 8
        parent: toolbarItem
        visible: self.visible
        GSearchField {
            id: search_field
        }
        LinkButton {
            font.pixelSize: 16
            font.weight: 600
            text: qsTrId('Export')
            enabled: self.account.context && list_view.count > 0
            onClicked: {
                const dialog = export_addresses_dialog.createObject(self, {
                    context: self.account.context,
                    account: self.account,
                })
                dialog.open()
            }
        }
    }
}
