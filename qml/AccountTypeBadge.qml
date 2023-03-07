import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    required property Account account

    function typeLabel (account) {
        switch (account.type) {
            case '2of2': return qsTrId('id_standard_account')
            case '2of3': return qsTrId('id_2of3_account')
            case '2of2_no_recovery': return qsTrId('id_amp_account')
            case 'p2sh-p2wpkh': return qsTrId('id_legacy_segwit_bip49')
            case 'p2wpkh': return qsTrId('id_segwit_bip84')
            default: return qsTrId('id_unknown')
        }
    }

    function networkLabel (network) {
        return network.electrum ? qsTrId('id_singlesig') : qsTrId('id_multisig_shield')
    }

    id: self

    Image {
        fillMode: Image.PreserveAspectFit
        sourceSize.height: 16
        sourceSize.width: 16
        source: self.account.network.electrum ? 'qrc:/svg/key.svg' : 'qrc:/svg/multi-sig.svg'
    }

    Label {
        font.pixelSize: 10
        font.capitalization: Font.AllUppercase
        color: 'white'
        text: networkLabel(self.account.network) + ' / ' + typeLabel(self.account)
    }
}
