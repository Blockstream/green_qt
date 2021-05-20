import Blockstream.Green 0.1
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
            text: qsTrId('id_addresses')
            font.pixelSize: 22
            font.styleName: 'Bold'
        }
        HSpacer {
        }
        GSearchField {
            id: search_field
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
            hoverEnabled: false
            width: list_view.width
            onClicked: self.clicked(address)
        }

        ScrollIndicator.vertical: ScrollIndicator { }

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
