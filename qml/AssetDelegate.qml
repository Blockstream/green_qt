import Blockstream.Green
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

Button {
    property Balance balance
    property bool hasDetails: balance.asset.hasData && balance.asset.data.name !== 'btc'

    id: self
    hoverEnabled: hasDetails
    padding: constants.p2
    background: Rectangle {
        color: self.hovered ? constants.c700 : self.highlighted ? constants.c600 : constants.c800
        radius: 4
        border.width: self.highlighted ? 1 : 0
        border.color: constants.g500
    }
    contentItem: BalanceItem {
        balance: self.balance
    }
}
