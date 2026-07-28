import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

TTextField {
    signal cleared

    required property Session session
    required property Convert convert

    property bool fiat: false
    property bool dynamic: true
    property string unit: self.session?.unit ?? ''
    property bool embed: false
    property real spacing: 4

    function testnetUnit(unit) {
        if (unit === 'BTC' || unit === 'btc') return 'TEST';
        if (unit === 'mBTC' || unit === 'mbtc') return 'mTEST';
        if (unit === '\u00B5BTC' || unit === '\u00B5btc' || unit === 'ubtc') return '\u00B5TEST';
        if (unit === 'bits') return 'bTEST';
        if (unit === 'sats') return 'sTEST';
    }
    function displayLabel(unit) {
        const prefix = self.session?.network.liquid ? 'L' : ''
        const mainnet = self.session?.context.mainnet ?? true
        return prefix + (mainnet ? unit : testnetUnit(unit))
    }

    readonly property var unitOptions: {
        const btcOptions = ['BTC', 'mBTC', '\u00B5BTC', 'sats']
            .map(unit => ({ value: unit, label: displayLabel(unit) }))

        const isBtcUnit = !!btcOptions.find(({ label }) => label === self.convert.output.unit)
        
        // Show only asset unit for non-Bitcoin assets, show all units for Bitcoin
        return isBtcUnit ? btcOptions : [{ value: self.convert.output.unit, label: self.convert.output.unit }]
    }

    property alias leftItem: left_loader.sourceComponent
    property alias thirdLabel: third_label.text
    
    function setUnit(unit) {
        self.fiat = false
        self.unit = unit
        self.convert.changeUnit(unit)
        const text = self.fiat ? self.convert.fiat.amount : self.convert.format(self.unit).amount
        if (self.text.length > 0) {
            self.text = self.readOnly ? text : text.replace(/\s+/g, '')
        } else {
            self.text = ''
        }
    }

    function setFiat() {
        self.fiat = true
        if (self.text.length > 0) {
            const text = self.convert.fiat.amount
            self.text = self.readOnly ? text : text.replace(/\s+/g, '')
        } else {
            self.text = ''
        }
    }

    function toggleFiat() {
        if (self.fiat) {
            self.setUnit(self.unit)
        } else {
            setFiat()
        }
    }

    function setText(value) {
        self.convert.input = value.length === 0 ? {} : self.fiat ? { fiat: value } : { text: value }
    }

    function clearText() {
        self.clear()
        self.setText('')
        self.cleared()
    }

    Component.onCompleted: {
        if (Object.keys(self.convert.input).length > 0) {
            const text = self.fiat ? self.convert.fiat.amount : self.convert.output.amount
            self.text = self.readOnly ? text : text.replace(/\s+/g, '')
        }
    }

    onReadOnlyChanged: {
        if (!self.readOnly) {
            self.text = self.text.replace(/\s+/g, '')
        } else if (self.fiat) {
            self.text = self.convert?.fiat.amount ?? ''
        } else {
            self.text = self.convert?.output.amount ?? ''
        }
    }

    Connections {
        target: self.convert
        function onInputCleared() {
            self.clear()
        }
        function onOutputChanged() {
            if ((self.readOnly || !self.activeFocus) && (!self.fiat || !self.convert.fiat.available) && Object.keys(self.convert.input).length > 0) {
                const amount = self.convert.output.amount
                if (self.text !== '' || amount !== '0') {
                    self.text = amount
                }
            }
        }
        function onFiatChanged() {
            if ((self.readOnly || !self.activeFocus) && self.fiat && self.convert.fiat.available) {
                const amount = self.convert.fiat.amount
                if (self.text !== '' || amount !== '0') {
                    self.text = amount
                }
            }
        }
    }
    onTextChanged: self.text = self.text.replace(/\s+/g, '')
    onTextEdited: self.setText(self.text)

    Layout.fillWidth: true
    id: self
    topPadding: self.embed ? 0 : 16
    bottomPadding: {
        if (!self.convert.fiat.available) return self.embed ? 0 : 16
        return self.spacing + Math.max(second_label.height, third_label.height) + (self.embed ? 0 : 16)
    }
    leftPadding: {
        const l = (self.embed ? 0 : 16) + left_loader.anchors.leftMargin + left_loader.width + 7
        const r = (self.embed ? 0 : 16) + 7 + unit_label.width
        return self.horizontalAlignment === TextInput.AlignHCenter ? Math.max(l, r) : l
    }
    rightPadding: {
        const l = (self.embed ? 0 : 16) + left_loader.anchors.leftMargin + left_loader.width + 7
        const r = (self.embed ? 0 : 16) + 7 + unit_label.width
        return self.horizontalAlignment === TextInput.AlignHCenter ? Math.max(l, r) : r
    }
    validator: AmountValidator {
    }
    horizontalAlignment: TextInput.AlignHCenter
    font.pixelSize: 24
    font.weight: 500
    Loader {
        id: left_loader
        // anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: self.embed ? 0 : 18
        anchors.bottom: self.baseline
        anchors.bottomMargin: -4.5
        // visible: !self.embed &&
        sourceComponent: CircleButton {
            focusPolicy: Qt.NoFocus
            icon.source: 'qrc:/svg2/x-circle.svg'
            visible: !self.readOnly && self.text !== ''
            onClicked: self.clearText()
        }
    }
    AbstractButton {
        id: unit_label
        leftPadding: 0
        rightPadding: 0
        bottomPadding: 0
        topPadding: 0
        anchors.right: parent.right
        anchors.rightMargin: self.embed ? 0 : 16
        //anchors.verticalCenter: parent.verticalCenter
        //anchors.verticalCenterOffset: self.convert.fiat.available ? -2 : 3
        anchors.bottom: self.baseline
        anchors.bottomMargin: -4.5
        enabled: self.dynamic && (self.convert.fiat.available ?? false)
        contentItem: RowLayout {
            opacity: unit_label.enabled && unit_label.hovered ? 1 : 0.9
            spacing: 4
            Label {
                color: '#00BCFF'
                font.pixelSize: 18
                font.weight: 500
                text: (self.fiat ? self.convert.fiat.currency : self.convert.output.unit) ?? ''
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/caret-down.svg'
                visible: unit_label.enabled
            }
        }
        onClicked: {
            if (!unit_menu.visible) {
                unit_menu.open()
            }
        }
        background: Rectangle {
            border.width: 2
            border.color: '#00BCFF'
            color: 'transparent'
            visible: unit_label.visualFocus
        }
        GMenu {
            id: unit_menu
            x: unit_menu_anchors.x
            y: unit_menu_anchors.y
            pointerX: unit_menu_anchors.pointerX
            pointerY: unit_menu_anchors.pointerY
            GMenu.Item {
                enabled: self.convert.fiat.available
                hideIcon: true
                text: self.session?.settings?.pricing?.currency ?? ''
                onClicked: {
                    unit_menu.close()
                    self.setFiat()
                }
            }
            Repeater {
                model: self.unitOptions
                delegate: GMenu.Item {
                    required property var modelData
                    hideIcon: true
                    text: modelData.label
                    onClicked: {
                        unit_menu.close()
                        self.setUnit(modelData.value)
                    }
                }
            }
        }
    }
    property var unit_menu_anchors: {
        const p = UtilJS.dynamicScenePosition(unit_label, 0, unit_label.height + 8 + unit_menu.height)
        const wh = ApplicationWindow.window?.height ?? 0
        return {
            x: unit_label.width * 0.5 - unit_menu.width * 0.8,
            y: p.y > wh ? -unit_menu.height - 8 : unit_label.height + 8,
            pointerX: 0.8,
            pointerY: p.y > wh ? 1 : 0
        }
    }

    Label {
        id: second_label
        anchors.horizontalCenter: self.horizontalAlignment === TextInput.AlignHCenter ? parent.horizontalCenter : undefined
        anchors.right: self.horizontalAlignment === TextInput.AlignRight ? parent.right : undefined
        anchors.rightMargin: self.embed ? 0 : 16
        anchors.bottom: self.bottom
        anchors.bottomMargin: self.embed ? 0 : 16
        color: second_hover_handler.hovered ? '#FAFAFA' : '#525252'
        font.features: { 'calt': 0, 'zero': 1 }
        font.pixelSize: 12
        font.weight: 500
        horizontalAlignment: Label.AlignHCenter
        text: self.fiat ? self.convert.output.label : self.convert.fiat.label
        visible: self.text !== '' && self.convert.fiat.available
        TapHandler {
            enabled: self.dynamic
            onTapped: self.toggleFiat()
        }
        HoverHandler {
            id: second_hover_handler
            enabled: self.dynamic
        }
    }
    Label {
        id: third_label
        anchors.horizontalCenter: self.horizontalAlignment === TextInput.AlignHCenter ? parent.horizontalCenter : undefined
        anchors.left: parent.left
        anchors.leftMargin: self.embed ? 0 : 16
        anchors.bottom: self.bottom
        anchors.bottomMargin: self.embed ? 0 : 16
        color: '#A0A0A0'
        font.features: { 'calt': 0, 'zero': 1 }
        font.pixelSize: 12
        font.weight: 500
    }
}
