import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls

Label {
    required property var address
    property bool copyEnabled: false
    TapHandler {
        onTapped: {
            timer.restart()
            Clipboard.copy(self.address.address)
        }
    }
    HoverHandler {
        enabled: self.copyEnabled
        id: hover_handler
    }
    Timer {
        id: timer
        repeat: false
        interval: 1000
    }
    Collapsible {
        id: collapsible
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        animationVelocity: 500
        collapsed: !hover_handler.hovered
        horizontalCollapse: true
        verticalCollapse: false
        Image {
            x: 8
            source: timer.running ? 'qrc:/svg2/check.svg' : 'qrc:/svg2/copy.svg'
        }
    }
    id: self
    font.family: 'Roboto Mono'
    font.features: { 'calt': 0, 'zero': 1 }
    font.pixelSize: 16
    font.weight: 400
    horizontalAlignment: Text.AlignHCenter
    elide: Label.ElideMiddle
    rightPadding: collapsible.width
    text: {
        if (self.address instanceof Address) {
            let parts = self.address.address.match(/.{1,4}/g) ?? []
            parts = parts
                .map((part, index) => `<span style="color:${index < 2 || index > parts.length - 3 ? '#00BCFF' : '#FFFFFF'}">${part}</span>`)
            if (self.elide !== Label.ElideNone) {
                if (parts.length > 8) {
                    return parts.slice(0, 4).join(' ') + '<br/>⋯<br/>' + parts.slice(-4).join(' ')
                }
                if (parts.length === 8) {
                    return parts.slice(0, 4).join(' ') + '<br/>' + parts.slice(-4).join(' ')
                }
            }
            return parts.join(' ')
        } else {
            return self.address ?? ''
        }
    }
    textFormat: Label.RichText
    wrapMode: Label.WordWrap
}
