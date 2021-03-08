import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

ItemDelegate {
    id: self

    required property Address address

    hoverEnabled: true
    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0
    background: Item {}

    spacing: 8

    contentItem: RowLayout {
        spacing: 16

        Label {
            Layout.maximumWidth: 200
            elide: Text.ElideRight
            text: address.data["address"]
            font.pixelSize: 12
            font.capitalization: Font.AllUppercase
            font.styleName: 'Regular'
            opacity: 0.6
        }

        Label {
            text: address.data["address_type"]
            font.pixelSize: 12
            font.capitalization: Font.AllUppercase
            font.styleName: 'Regular'
            opacity: 0.6
        }

        Label {
            text: address.data["tx_count"]
            font.pixelSize: 12
            font.capitalization: Font.AllUppercase
            font.styleName: 'Regular'
            opacity: 0.6
        }
    }
}
