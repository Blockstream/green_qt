import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.3

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
}
