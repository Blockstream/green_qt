import QtQuick.Controls 2.13

ComboBox {
    property int blocks: model[currentIndex].blocks

    function fee(label, duration, blocks) {
        const text = qsTr(label) + ' ~ ' + qsTr(duration) + ' ( '+ Math.round(wallet.events.fees[blocks] / 10 + 0.5) / 100 + ' satoshi/vbyte)'
        return { label, duration, blocks, text }
    }

    flat: true
    model: [
        fee('Fast', '10 Minutes', 3),
        fee('Medium', '2 Hours', 12),
        fee('Slow', '4 Hours', 24)
    ]
    textRole: 'text'
}
