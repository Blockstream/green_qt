import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

ItemDelegate {
    required property var address
    id: self
    hoverEnabled: true
    padding: 0
    background: null
    spacing: constants.p2
    contentItem: RowLayout {
        spacing: constants.p3
        CopyableLabel {
            Layout.fillWidth: true
            Layout.leftMargin: constants.p1
            elide: Text.ElideRight
            text: address.data["address"]
            font.pixelSize: 14
            font.styleName: 'Regular'
        }
        Label {
            text: address.data["address_type"]
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 14
            font.capitalization: Font.AllUppercase
            font.styleName: 'Regular'
            Layout.minimumWidth: 50
        }
        Label {
            text: address.data["tx_count"]
            horizontalAlignment: Label.AlignHCenter
            font.pixelSize: 14
            font.capitalization: Font.AllUppercase
            font.styleName: 'Regular'
            Layout.minimumWidth: 50
            Layout.rightMargin: constants.p1
        }
    }
}
