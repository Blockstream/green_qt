import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

TextField {
    property var error
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
        self.text = self.readOnly ? text : text.replace(/\s+/g, '')
    }
    function setFiat() {
        self.fiat = true
        const text = self.convert.fiat.amount
        self.text = self.readOnly ? text : text.replace(/\s+/g, '')
    }
    function toggleFiat() {
        if (self.fiat) {
            self.setUnit(self.unit)
        } else {
            setFiat()
        }
    }
    function setText(value) {
        self.convert.input = self.fiat ? { fiat: value } : { text: value }
    }
    function clearText() {
        self.clear()
        self.setText('')
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
                self.text = self.convert.output.amount
            }
        }
        function onFiatChanged() {
            if ((self.readOnly || !self.activeFocus) && self.fiat && self.convert.fiat.available) {
                self.text = self.convert.fiat.amount
            }
        }
    }

    onTextEdited: self.setText(self.text)

    Layout.fillWidth: true
    id: self
    topPadding: 22
    bottomPadding: self.convert.fiat.available ? 32 : 22
    leftPadding: 60
    rightPadding: 15 + 7 + unit_label.width
    validator: AmountValidator {
    }
    background: Rectangle {
        color: Qt.lighter('#222226', !self.readOnly && self.hovered ? 1.2 : 1)
        radius: 5
        border.width: !!self.error ? 2 : 0
        border.color: '#C91D36'
        Rectangle {
            border.width: 2
            border.color: '#00B45A'
            color: 'transparent'
            radius: 9
            anchors.fill: parent
            anchors.margins: -4
            z: -1
            visible: {
                if (self.readOnly && self.activeFocus) {
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
        leftPadding: 4
        rightPadding: 4
        bottomPadding: 2
        topPadding: 2
        anchors.right: parent.right
        anchors.rightMargin: 15
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: self.convert.fiat.available ? -2 : 3
        enabled: self.dynamic && (self.convert.fiat.available ?? false)
        contentItem: RowLayout {
            spacing: 4
            Label {
                color: unit_label.enabled && unit_label.hovered ? '#00DD6E' : '#00B45A'
                font.pixelSize: 16
                font.weight: 500
                text: self.fiat ? self.convert.fiat.currency : self.convert.output.unit
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/caret-down.svg'
                visible: unit_label.enabled
            }
        }
        onClicked: unit_menu.open()
        background: null
        GMenu {
            id: unit_menu
            x: unit_label.width * 0.5 - unit_menu.width * 0.8
            y: unit_label.height + 8
            pointerX: 0.8
            pointerY: 0
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
    Label {
        id: second_label
        anchors.right: parent.right
        anchors.rightMargin: self.rightPadding
        anchors.top: parent.baseline
        anchors.topMargin: 8
        text: self.fiat ? self.convert.output.label : self.convert.fiat.label
        color: '#FFF'
        opacity: 0.4
        font.pixelSize: 12
        font.weight: 500
        visible: self.convert.fiat.available
        TapHandler {
            enabled: self.dynamic
            cursorShape: Qt.ArrowCursor
            onTapped: self.toggleFiat()
        }
    }
}
