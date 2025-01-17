import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

TTextField {
    signal cleared
    property bool fiat: false
    property bool dynamic: true
    required property string unit
    readonly property var units: ['BTC', 'sats', 'mBTC', '\u00B5BTC']
    required property Convert convert

    function setUnit(unit) {
        self.fiat = false
        self.unit = unit
        self.convert.unit = unit
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
        const text = self.fiat ? self.convert.fiat.amount : self.convert.output.amount
        self.text = self.readOnly ? text : text.replace(/\s+/g, '')
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
    topPadding: 22
    bottomPadding: self.convert.fiat.available ? 32 : 22
    leftPadding: 60
    rightPadding: 15 + 7 + unit_label.width
    validator: AmountValidator {
    }
    horizontalAlignment: TextInput.AlignHCenter
    font.pixelSize: 30
    font.weight: 500
    CircleButton {
        focusPolicy: Qt.NoFocus
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 18
        visible: !self.readOnly && self.text !== ''
        icon.source: 'qrc:/svg2/x-circle.svg'
        onClicked: self.clearText()
    }
    AbstractButton {
        id: unit_label
        leftPadding: 6
        rightPadding: 6
        bottomPadding: 4
        topPadding: 4
        anchors.right: parent.right
        anchors.rightMargin: 15
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: self.convert.fiat.available ? -2 : 3
        enabled: self.dynamic && (self.convert.fiat.available ?? false)
        contentItem: RowLayout {
            spacing: 4
            Label {
                color: unit_label.enabled && unit_label.hovered ? '#00DD6E' : '#00B45A'
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
            border.color: '#00B45A'
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
                text: self.convert.account.session.settings.pricing.currency
                onClicked: {
                    unit_menu.close()
                    self.setFiat()
                }
            }
            Repeater {
                model: self.units
                delegate: GMenu.Item {
                    hideIcon: true
                    text: (self.convert.account.network.liquid ? 'L-' : '') + modelData
                    onClicked: {
                        unit_menu.close()
                        self.setUnit(modelData)
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
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: (self.leftPadding - self.rightPadding) / 2
        anchors.top: parent.baseline
        anchors.topMargin: 8
        horizontalAlignment: Label.AlignHCenter
        text: self.fiat ? self.convert.output.label : self.convert.fiat.label
        color: '#FFF'
        opacity: 0.4
        font.features: { 'calt': 0, 'zero': 1 }
        font.pixelSize: 12
        font.weight: 500
        visible: self.text !== '' && self.convert.fiat.available
        TapHandler {
            enabled: self.dynamic
            cursorShape: Qt.ArrowCursor
            onTapped: self.toggleFiat()
        }
    }
}
