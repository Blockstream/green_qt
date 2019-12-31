import QtQuick.Controls 2.13

ComboBox {
    property int blocks: model[currentIndex].blocks

    function fee(label, duration, blocks) {
        const text = qsTr(label) + ' ' + qsTr(duration) + ' ( '+ Math.round(wallet.events.fees[blocks] / 10 + 0.5) / 100 + ' satoshi/vbyte)'
        return { label, duration, blocks, text }
    }

    flat: true
    model: [
        fee(qsTr('id_fast'), qsTr('id_1030_minutes'), 3),
        fee(qsTr('id_medium'), qsTr('id_2_hours'), 12),
        fee(qsTr('id_slow'), qsTr('id_4_hours'), 24)
    ]
    textRole: 'text'
}
