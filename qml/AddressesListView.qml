import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    required property Account account
    signal clicked(Address address)

    id: self
    spacing: constants.p1
    background: null
    header: GHeader {
        Label {
            Layout.alignment: Qt.AlignVCenter
            text: qsTrId('id_addresses')
            font.pixelSize: 20
            font.styleName: 'Bold'
        }
        HSpacer {
        }
        GSearchField {
            Layout.alignment: Qt.AlignVCenter
            id: search_field
        }
        GButton {
            Layout.alignment: Qt.AlignVCenter
            visible: Settings.enableExperimental
            text: qsTrId('Export')
            enabled: self.account.wallet.ready && list_view.count > 0
            onClicked: export_addresses_popup.createObject(window, { account: self.account }).open()
            ToolTip.text: qsTrId('Export addresses to CSV file')
        }
    }
    contentItem: GListView {
        id: list_view
        clip: true
        spacing: 0
        model: AddressListModelFilter {
            id: address_model_filter
            filter: search_field.text
            model: AddressListModel {
                id: address_model
                account: self.account
            }
        }
        delegate: AddressDelegate {
            width: ListView.view.contentWidth
            onClicked: self.clicked(address)
        }
        BusyIndicator {
            width: 32
            height: 32
            running: address_model.fetching
            anchors.margins: 8
            Layout.alignment: Qt.AlignHCenter
            opacity: address_model.fetching ? 1 : 0
            Behavior on opacity { OpacityAnimator {} }
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
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
}
