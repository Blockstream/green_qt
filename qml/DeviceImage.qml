import Blockstream.Green
import QtQuick

Image {
    required property Device device
    smooth: true
    mipmap: true
    fillMode: Image.PreserveAspectFit
    horizontalAlignment: Image.AlignHCenter
    source: {
        if (!device) return ''
        switch (device.type) {
        case Device.BlockstreamJade: return 'qrc:/svg/blockstream_jade.svg'
        case Device.LedgerNanoS: return 'qrc:/svg/ledger_nano_s.svg'
        case Device.LedgerNanoX: return 'qrc:/svg/ledger_nano_x.svg'
        }
    }
}
