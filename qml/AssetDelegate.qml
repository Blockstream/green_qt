import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ItemDelegate {
    property Balance balance
    property bool hasDetails: balance.asset.hasData && balance.asset.data.name !== 'btc'

    id: self
    hoverEnabled: hasDetails
    topPadding: 16
    leftPadding: 16
    rightPadding: 16
    bottomPadding: 16
    background: Item {
        Rectangle {
            anchors.fill: parent
            visible: self.hovered
            color: '#00B45A'
            opacity: 0.08
        }
        Rectangle {
            color: '#FFFFFF'
            opacity: 0.1
            width: parent.width
            height: 1
            y: parent.height - 1
        }
    }
    contentItem: BalanceItem {
        balance: self.balance
    }
}
