import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Pane {
    id: self
    property var device
    property var details
    readonly property bool connected: !!device
    readonly property var _details: device ? device.details : details
    background: null
    padding: 0
    hoverEnabled: true
    contentItem: Image {
        opacity: connected ? 1 : 0.5
        smooth: true
        mipmap: true
        fillMode: Image.PreserveAspectFit
        horizontalAlignment: Image.AlignHCenter
        source: {
            const type = _details?.type ?? ''
            if (type === 'jade') return 'qrc:/svg/blockstream_jade.svg'
            if (type === 'nanos') return 'qrc:/svg/ledger_nano_s.svg'
            if (type === 'nanox') return 'qrc:/svg/ledger_nano_x.svg'
            return ''
        }
        sourceSize.height: 16
    }
    ToolTip.text: _details.name
    ToolTip.visible: hovered
    ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
}
