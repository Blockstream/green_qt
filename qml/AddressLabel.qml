import Blockstream.Green
import QtQuick
import QtQuick.Controls

Label {
    required property var address
    id: self
    font.family: 'Roboto Mono'
    font.features: { 'calt': 0, 'zero': 1 }
    font.pixelSize: 16
    font.weight: 400
    horizontalAlignment: Text.AlignHCenter
    elide: Label.ElideMiddle
    text: {
        if (self.address instanceof Address) {
            let parts = self.address.address.match(/.{1,4}/g) ?? []
            parts = parts
                .map((part, index) => `<span style="color:${index < 2 || index > parts.length - 3 ? '#00B45A' : '#FFFFFF'}">${part}</span>`)
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
