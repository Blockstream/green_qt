import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    signal signMessage(Address address)
    signal addressClicked(Address address)
    required property Account account
    property bool search: false
    id: self
    padding: 0
    focusPolicy: Qt.ClickFocus
    header: Collapsible {
        id: collapsible
        collapsed: !self.search
        animationVelocity: 300
        Pane {
            width: collapsible.width
            background: null
            padding: 20
            contentItem: RowLayout {
                spacing: 20
                SearchField {
                    Layout.fillWidth: true
                    id: search_field
                }
                LinkButton {
                    text: qsTrId('id_cancel')
                    onClicked: {
                        search_field.clear()
                        self.search = false
                    }
                }
            }
        }
    }
    background: Rectangle {
        color: '#161921'
        border.width: 1
        border.color: '#1F222A'
        radius: 4
    }
    contentItem: TListView {
        id: list_view
        bottomMargin: 120
        spacing: -1
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
        parent: toolbarItem
        visible: self.visible
        spacing: 10
        LinkButton {
            font.pixelSize: 16
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
        Rectangle {
            Layout.alignment: Qt.AlignCenter
            Layout.preferredHeight: 24
            Layout.preferredWidth: 1
            color: '#FFF'
            opacity: 0.2
        }
        CircleButton {
            icon.source: 'qrc:/svg2/search_green.svg'
            enabled: !self.search
            onClicked: {
                self.search = true
                search_field.forceActiveFocus()
            }
        }
    }
}
