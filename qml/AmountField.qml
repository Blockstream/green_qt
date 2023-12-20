import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

TextField {
    required property Account account
    required property Asset asset
    id: self
    readonly property var satoshi: convert.result?.satoshi ?? ''

    property bool fiat: false
    property string unit: self.account.session.unit

    readonly property var units: ['BTC', 'sats', 'mBTC', '\u00B5BTC']

    function norm_unit(unit) {
        return unit === '\u00B5BTC' ? 'ubtc' : unit.toLowerCase()
    }

    property string xunit: norm_unit(self.account.session.unit)

    Convert {
        id: convert
        account: self.account
        asset: self.asset
        unit: self.fiat ? 'fiat' : norm_unit(self.unit)
        onValueChanged: self.text = convert.value
    }

    onTextEdited: convert.value = self.text

    Layout.fillWidth: true
    topPadding: 22
    bottomPadding: convert.fiat ? 32 : 22
    leftPadding: 15
    rightPadding: self.leftPadding + 7 + unit_label.width
    background: Rectangle {
        color: '#222226'
        radius: 5
        Rectangle {
            border.width: 2
            border.color: '#00B45A'
            color: 'transparent'
            radius: 9
            anchors.fill: parent
            anchors.margins: -4
            z: -1
            visible: {
                if (self.activeFocus) {
                    switch (self.focusReason) {
                    case Qt.TabFocusReason:
                    case Qt.BacktabFocusReason:
                    case Qt.ShortcutFocusReason:
                        return true
                    }
                }
                return false
            }
        }
    }
    horizontalAlignment: TextInput.AlignRight
    font.pixelSize: 24
    font.weight: 500
    Label {
        id: unit_label
        anchors.right: parent.right
        anchors.rightMargin: self.leftPadding
        anchors.baseline: parent.baseline
        text: {
            if (convert.fiat) {
                return self.fiat ? self.account.session.settings.pricing.currency : self.unit
            } else {
                return convert.asset?.data?.ticker ?? ''
            }
        }
        color: '#00B45A'
        font.pixelSize: 18
        font.weight: 500
        TapHandler {
            cursorShape: Qt.ArrowCursor
            enabled: !self.fiat
            onTapped: self.unit = self.units[(self.units.indexOf(self.unit) + 1) % units.length]
        }
    }
    Label {
        id: second_label
        anchors.right: parent.right
        anchors.rightMargin: self.rightPadding
        anchors.top: parent.baseline
        anchors.topMargin: 8
        text: {
            if (self.fiat) {
                const amount = convert.result[self.xunit]
                return amount ? [amount, self.account.session.unit].join(' ') : ''
            } else {
                return convert.result.fiat ? [convert.result.fiat ?? '', convert.result.fiat_currency ?? ''].join(' ') : ''
            }
        }
        color: '#FFF'
        opacity: 0.4
        font.pixelSize: 12
        font.weight: 500
        visible: convert.fiat
        TapHandler {
            onTapped: self.fiat = !self.fiat
        }
    }
}
