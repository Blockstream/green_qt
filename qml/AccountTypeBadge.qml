import Blockstream.Green 0.1
import QtQuick 2.15
import QtQuick.Controls 2.5

Label {
    property Account account
    font.pixelSize: 10
    font.capitalization: Font.AllUppercase
    leftPadding: 8
    rightPadding: 8
    topPadding: 4
    bottomPadding: 4
    color: 'white'
    background: Rectangle {
        color: constants.c400
        radius: 4
    }
    visible: !!text
    text: {
        if (account) {
            switch (account.type) {
                case '2of3': return qsTrId('id_2of3_account')
                case '2of2_no_recovery': return qsTrId('id_amp_account')
                case 'p2sh-p2wpkh': return qsTrId('id_legacy_account')
                case 'p2wpkh': return qsTrId('id_segwit_account')
            }
        }
    }
}
