import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

GPane {
    property real contentY: list_view.contentY
    required property Account account
    signal clicked(Address address)

    id: self
    background: Rectangle {
        color: '#161921'
        border.width: 1
        border.color: '#1F222A'
        radius: 4
    }
    contentItem: TListView {
        id: list_view
        spacing: 8

        model: AddressListModelFilter {
            filter: search_field.text
            model: address_model
        }
        delegate: AddressDelegate {
            width: ListView.view.width
            onClicked: self.clicked(address)
        }
    }

    Component {
        id: export_addresses_popup
        Popup {
            required property Account account
            id: dialog
            anchors.centerIn: Overlay.overlay
            closePolicy: Popup.NoAutoClose
            modal: true
            Overlay.modal: Rectangle {
                color: "#70000000"
            }
            onClosed: destroy()
            onOpened: controller.save()
            ExportAddressesController {
                id: controller
                account: dialog.account
                onSaved: dialog.close()
            }
            BusyIndicator {
            }
        }
    }

    RowLayout {
        spacing: 8
        parent: toolbarItem
        visible: self.visible
        GSearchField {
            id: search_field
        }
        GButton {
            visible: Settings.enableExperimental
            text: qsTrId('Export')
            enabled: self.account.context && list_view.count > 0
            onClicked: export_addresses_popup.createObject(window, { account: self.account }).open()
            ToolTip.text: qsTrId('Export addresses to CSV file')
        }
    }
}
