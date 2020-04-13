import QtQuick.Controls 2.13

ComboBox {
    property var extra: []
    property int feeRate: model[currentIndex].feeRate
    property int blocks: model[currentIndex].blocks

    function fee(label, duration, blocks) {
        const feeRate = wallet.events.fees[blocks] ;
        const text = qsTrId(label) + ' ' + qsTrId(duration) + ' ( '+ Math.round(feeRate / 10 + 0.5) / 100 + ' sat/vB)';
        return { blocks, feeRate, text }
    }

    // TODO: update when Liquid develops a block space market
    property var liquid_fees: [
        fee('id_fast', '~1' + ' ' + qsTrId('id_minute'), 3)
    ]
    property var fees: [
        fee('id_fast', 'id_1030_minutes', 3),
        fee('id_medium', 'id_2_hours', 12),
        fee('id_slow', 'id_4_hours', 24)
    ]

    flat: true
    model: (wallet.network.liquid ? liquid_fees : fees).concat(extra)
    textRole: 'text'
}
