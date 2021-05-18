import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

Button {
    property Balance balance
    property bool hasDetails: balance.asset.hasData && balance.asset.data.name !== 'btc'

    id: self
    hoverEnabled: true
    padding: constants.p2
    background: Rectangle {
        color: self.hovered && hasDetails ? constants.c700 : self.highlighted ? constants.c600 : constants.c800
        radius: 4
        border.width: self.highlighted ? 1 : 0
        border.color: constants.g500
    }
    contentItem: BalanceItem {
        balance: self.balance
    }
}
