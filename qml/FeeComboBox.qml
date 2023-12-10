import QtQuick.Controls
import Blockstream.Green

GComboBox {
    required property Account account
    property var extra: []
    property int feeRate: model[currentIndex].feeRate || 0
    property int blocks: model[currentIndex].blocks || 0
    property alias fees: fee_estimates.fees

    function fee(label, duration, blocks) {
        const feeRate = fee_estimates.fees[blocks] ;
        const text = qsTrId(label) + ' ' + qsTrId(duration) + ' ( '+ Math.round(feeRate / 10 + 0.5) / 100 + ' sat/vB)';
        return { blocks, feeRate, text }
    }

    // TODO: update when Liquid develops a block space market
    property var liquid_fees: [
        fee('id_fast', '~1' + ' ' + qsTrId('id_minute'), 3)
    ]
    property var bitcoin_fees: [
        fee('id_fast', 'id_1030_minutes', 3),
        fee('id_medium', 'id_2_hours', 12),
        fee('id_slow', 'id_4_hours', 24)
    ]

    id: self
    model: (self.account.network.liquid ? liquid_fees : bitcoin_fees).concat(extra)
    textRole: 'text'

    FeeEstimates {
        id: fee_estimates
        session: self.account.session
    }
}
