import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

ItemDelegate {
    property Balance balance
    property bool hasDetails: balance.asset.hasData && balance.asset.data.name !== 'btc'
    property bool showIndicator: true

    id: balance_delegate

    background.opacity: 0.4

    contentItem: BalanceItem {
        balance: balance_delegate.balance
        Item {
            visible: showIndicator
            width: 16
            height: 16
            Layout.alignment: Qt.AlignVCenter

            Image {
                visible: hasDetails
                anchors.centerIn: parent
                sourceSize.width: 16
                sourceSize.height: 16
                source: 'assets/svg/arrow_right.svg'
            }
        }
    }
}
