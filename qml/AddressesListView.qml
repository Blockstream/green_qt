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
    /*
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
            enabled: self.account.context && list_view.count > 0
            onClicked: export_addresses_popup.createObject(window, { account: self.account }).open()
            ToolTip.text: qsTrId('Export addresses to CSV file')
        }
    }
    */

    contentItem: TListView {
        id: list_view
        spacing: 8
        model: AddressListModelFilter {
            id: address_model_filter
//            filter: search_field.text
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
            running: address_model.dispatcher.busy
            anchors.margins: 8
            Layout.alignment: Qt.AlignHCenter
            opacity: address_model.dispatcher.busy ? 1 : 0
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

    component TListView: ListView {
        ScrollIndicator.vertical: ScrollIndicator { }
        contentWidth: width
        displayMarginBeginning: 300
        displayMarginEnd: 100
    }
}
