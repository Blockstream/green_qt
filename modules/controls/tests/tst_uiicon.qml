import Blockstream.Controls
import Blockstream.Testing
import Blockstream.Theme
import QtQuick

GreenTestCase {
    id: self
    name: 'tst_uiicon'
    when: windowShown
    width: 160
    height: 160

    Rectangle {
        anchors.fill: parent
        color: '#204060'
    }

    Component {
        id: icon_component
        UiIcon {
            name: Theme.icons.jade
            size: 64
        }
    }

    function createIcon(properties = {}) {
        const icon = createTemporaryObject(icon_component, self, properties)
        verify(icon !== null)
        const source = self.findItems(icon, item => item instanceof Image)[0]
        tryCompare(source, 'status', Image.Ready)
        return icon
    }

    function requireShaderRenderer() {
        if (self.GraphicsInfo.api === GraphicsInfo.Software) {
            skip('Colorization pixel checks require a shader-capable renderer; rerun with a native platform.')
        }
    }

    function channelAt(image, channel, x, y) {
        return image[channel](Math.floor(image.width * x / 32), Math.floor(image.height * y / 32))
    }

    function test_originalColorsIgnoreTintAndTintAlpha() {
        const icon = createIcon({ colorize: false, color: Qt.rgba(1, 0, 0, 0) })
        tryVerify(() => {
            const image = grabImage(icon)
            return Math.abs(channelAt(image, 'green', 11, 20) - 136) <= 2
        })
        const image = grabImage(icon)
        // Interior samples from two differently colored Jade quadrants.
        for (const sample of [
            { x: 11, y: 20, red: 6, green: 136, blue: 111 },
            { x: 22, y: 12, red: 169, green: 219, blue: 211 }
        ]) {
            for (const channel of ['red', 'green', 'blue']) {
                verify(Math.abs(channelAt(image, channel, sample.x, sample.y) - sample[channel]) <= 2)
            }
        }
    }

    function test_colorizedTintAndAlpha_data() {
        return [
            { tag: 'opaque', alpha: 1 },
            { tag: 'translucent', alpha: 0.5 },
            { tag: 'transparent', alpha: 0 }
        ]
    }

    function test_colorizedTintAndAlpha(row) {
        requireShaderRenderer()
        const icon = createIcon({ color: Qt.rgba(1, 0, 0, row.alpha) })
        // grabImage captures the composited window, not the icon's own alpha.
        // Sample the white Jade quadrant tinted red over the opaque #204060 background.
        const expected = {
            red: Math.round(255 * row.alpha + 32 * (1 - row.alpha)),
            green: Math.round(64 * (1 - row.alpha)),
            blue: Math.round(96 * (1 - row.alpha))
        }
        tryVerify(() => {
            const image = grabImage(icon)
            return ['red', 'green', 'blue'].every(channel =>
                Math.abs(channelAt(image, channel, 11, 12) - expected[channel]) <= 2)
        })
    }

    function test_switchingColorizationRestoresOriginalColors() {
        requireShaderRenderer()
        const icon = createIcon({ color: 'red' })
        tryVerify(() => channelAt(grabImage(icon), 'green', 11, 20) <= 2)
        icon.colorize = false
        tryVerify(() => Math.abs(channelAt(grabImage(icon), 'green', 11, 20) - 136) <= 2)
        icon.colorize = true
        tryVerify(() => channelAt(grabImage(icon), 'green', 11, 20) <= 2)
    }
}
