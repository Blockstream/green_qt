import Blockstream.Green
import QtQuick
import QtQuick.Controls

import "util.js" as UtilJS

Label {
    required property Address address
    id: self
    color: '#000000'
    font.capitalization: Font.AllUppercase
    font.pixelSize: 12
    font.weight: 600
    topPadding: 2
    bottomPadding: 2
    leftPadding: 6
    rightPadding: 6
    text: localizedLabel(self.address.type)
    background: Rectangle {
        radius:  2
        color: '#68727D'
    }
}
