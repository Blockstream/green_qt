import Blockstream.Green 0.1
import QtQuick 2.0
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

Label {
    required property Transaction transaction
    required property int confirmations
    property bool showConfirmations: true
    readonly property bool liquid: transaction.account.wallet.network.liquid
    readonly property bool completed: confirmations >= (liquid ? 2 : 6)
    color: 'white'
    text: {
        if (completed) return qsTrId('id_completed')
        if (confirmations === 0) return qsTrId('id_unconfirmed')
        if (showConfirmations) {
            if (liquid) return qsTrId('id_12_confirmations')
            return qsTrId('id_d6_confirmations').arg(confirmations)
        } else {
            return qsTrId('id_pending_confirmation')
        }
    }
    font.pixelSize: 12
    font.styleName: 'Medium'
    font.capitalization: Font.AllUppercase

    topPadding: 4
    bottomPadding: 4
    leftPadding: 12
    rightPadding: 12
    background: Rectangle {
        radius: 4
        color: {
            if (confirmations === 0) return '#d2934a'
            if (completed) return constants.g500
            return '#474747'
        }
    }
}
