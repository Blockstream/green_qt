import Blockstream.Green
import QtQuick
import QtQuick.Controls

import "util.js" as UtilJS

Label {
    required property Account account
    id: self
    elide: Label.ElideRight
    // leftPadding: 8
    // rightPadding: 8
    // bottomPadding: 4
    // topPadding: 4
    background: null
    // background: Rectangle {
    //     radius: 2
    //     border.color: UtilJS.networkColor(self.account.network)
    //     border.width: 0.5
    //     color: 'transparent'
    // }
    font.weight: 500
    text: UtilJS.accountName(self.account)
}

