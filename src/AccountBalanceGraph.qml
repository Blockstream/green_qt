import QtQuick 2.0

Canvas {
    id: mycanvas
    visible: false
    anchors.fill: parent
    onPaint: {
        console.log('paint')
        var ctx = getContext("2d");
        ctx.strokeStyle = Qt.rgba(1, 1, 1, 1);
        ctx.lineWidth = 1;
//                        ctx.fillStyle = Qt.rgba(0, 0, 0, 1);
//                        ctx.fillRect(0, 0, width, height);
        ctx.clearRect(0, 0, width, height)

        if (!currentAccount) return

        var max = 0, b1 = 0, b2 = 0
        var i, tx
        var n = currentAccount.txs.length
        for (i in currentAccount.txs) {
            tx = currentAccount.txs[i]
            if (i === 0) {
                max = tx.satoshi.btc
                b1 = tx.block_height
                b2 = tx.block_height
            } else {
                if (tx.satoshi.btc > max) max = tx.satoshi.btc
                if (tx.block_height < b1) b1 = tx.block_height
                if (tx.block_height > b2) b2 = tx.block_height
            }
        }
        if (max > 0) {
            ctx.beginPath();
            for (i in currentAccount.txs) {
                tx = currentAccount.txs[i]
                if (i === 0) {
                    console.log('move to', 0, height * tx.satoshi.btc / max)
                    ctx.moveTo(0, height * tx.satoshi.btc / max)
                } else {
                    console.log('line to', width * i / (n - 1), height * tx.satoshi.btc / max)
                    ctx.lineTo(width * i / (n - 1), height * tx.satoshi.btc / max)
                }
            }
            ctx.stroke()
        }
    }
}
