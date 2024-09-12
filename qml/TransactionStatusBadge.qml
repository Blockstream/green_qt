import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Label {
    required property Transaction transaction
    required property int confirmations
    readonly property bool liquid: self.transaction.account.network.liquid
    readonly property bool completed: self.confirmations >= (self.liquid ? 2 : 6)
    readonly property var status: {
        switch (self.transaction.spv) {
        case Transaction.Verified:
            return { color: '#0A9252', text: qsTrId('id_verified'), visible: true }
        case Transaction.NotVerified:
            return { color: '#FF0000', text: qsTrId('id_invalid_merkle_proof'), visible: true }
        case Transaction.NotLongest:
            return { color: '#FF6600', text: qsTrId('id_not_on_longest_chain'), visible: true }
        case Transaction.InProgress:
            return { color: '#d2934a', text: qsTrId('id_verifying_transactions'), visible: true }
        }
        if (self.completed) {
            return { color: '#0A9252', text: qsTrId('id_completed'), visible: false }
        }
        if (self.confirmations === 0) {
            return { color: '#d2934a', text: qsTrId('id_unconfirmed'), visible: true }
        }
        if (self.liquid) {
            return { color: '#474747', text: qsTrId('id_12_confirmations'), visible: true }
        }
        return { color: '#474747', text: qsTrId('id_d6_confirmations').arg(self.confirmations), visible: true }
    }
    id: self
    color: 'white'
    text: self.status.text
    visible: self.status.visible

    font.pixelSize: 12
    font.weight: 400

    topPadding: 4
    bottomPadding: 4
    leftPadding: 12
    rightPadding: 12
    background: Rectangle {
        radius: height / 2
        color: self.status.color
    }
}
