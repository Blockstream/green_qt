import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3

ListView {
    id: list_view
    required property Account account
    signal clicked(Address address)
    clip: true

    spacing: 8

    model: AddressListModel {
        account: list_view.account
    }

    delegate: AddressDelegate {
        hoverEnabled: false
        width: list_view.width
        onClicked: list_view.clicked(address)
    }

    ScrollIndicator.vertical: ScrollIndicator { }

    Rectangle {
        anchors.fill: parent
        color: constants.c800
        visible: model.fetching
        opacity: visible ? 0.5 : 0
        Behavior on opacity { OpacityAnimator {} }
    }

    ColumnLayout {
        opacity: model.fetching ? 1 : 0
        Behavior on opacity { OpacityAnimator {} }
        anchors.centerIn: parent
        spacing: 16
        BusyIndicator {
            width: 32
            height: 32
            running: model.fetching
            anchors.margins: 8
            Layout.alignment: Qt.AlignHCenter
        }
        Label {
            text: 'Loading addresses...'
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
