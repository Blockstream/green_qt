import QtQuick.Controls 2.13

ComboBox {
    property int blocks: model[currentIndex].blocks

    function fee(label, duration, blocks) {
        const text = qsTr(label) + ' ' + qsTr(duration) + ' ( '+ Math.round(wallet.events.fees[blocks] / 10 + 0.5) / 100 + ' satoshi/vbyte)'
        return { label, duration, blocks, text }
    }

    flat: true
    // TODO: update when Liquid develops a block space market
    model: wallet.network.liquid ? [fee('id_fast', '~1' + ' ' + qsTr('id_minute'), 3)] : [
        fee('id_fast', 'id_1030_minutes', 3),
        fee('id_medium', 'id_2_hours', 12),
        fee('id_slow', 'id_4_hours', 24)
    ]
    textRole: 'text'
}
