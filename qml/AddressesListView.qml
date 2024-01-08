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
        id: export_addresses_popup
        WalletDialog {
            required property Account account
            id: dialog
            context: self.account.context
            header: null
            closePolicy: Popup.NoAutoClose
            topPadding: 20
            bottomPadding: 20
            leftPadding: 20
            rightPadding: 20
            width: 400
            height: 400
            onClosed: self.destroy()
            onOpened: controller.save()
            ExportAddressesController {
                id: controller
                context: dialog.account.context
                account: dialog.account
                onSaved: console.log('done') //dialog.close()
            }
            contentItem: GStackView {
                id: stack_view
                initialItem: StackViewPage {
                    title: qsTrId('Export Addresses to CSV File')
                    contentItem: ColumnLayout {
                        BusyIndicator {
                            Layout.alignment: Qt.AlignCenter
                        }
                    }
                }
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
        LinkButton {
            text: qsTrId('Export')
            enabled: self.account.context && list_view.count > 0
            onClicked: export_addresses_popup.createObject(self, { account: self.account }).open()
        }
    }
}
