import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

TextField {
    required property Account account
    required property Asset asset
    id: self
    readonly property var satoshi: convert.result?.satoshi ?? ''
    readonly property var result: convert.result
    property var error
    property bool fiat: false
    property string unit: self.account.session.unit
    property string value

    readonly property var units: ['BTC', 'sats', 'mBTC', '\u00B5BTC']
    property alias user: convert.user
    Convert {
        id: convert
        account: self.account
        asset: self.asset
        unit: self.fiat ? 'fiat' : UtilJS.normalizeUnit(self.unit)
        user: true
        value: self.value
        onValueChanged: if (!self.readOnly && convert.user) self.text = convert.value
        onUnitLabelChanged: {
            if (!self.readOnly && !convert.user) {
                self.text = convert.unitLabel.split(' ')[0]
            }
        }
    }

    function setValue(value) {
        convert.value = value
    }

    onUnitChanged: convert.user = true
    onFiatChanged: convert.user = true
    onTextEdited: {
        convert.user = true
        self.setValue(self.text)
    }

    Layout.fillWidth: true
    topPadding: 22
    bottomPadding: convert.fiat ? 32 : 22
    leftPadding: 50
    rightPadding: 15 + 7 + unit_label.width
    validator: AmountValidator {
    }
    background: Rectangle {
        color: '#222226'
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
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 24
        visible: self.enabled && !self.readOnly && self.text !== ''
        icon.source: 'qrc:/svg/erase.svg'
        onClicked: convert.value = ''
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
        anchors.verticalCenterOffset: convert.fiat ? -2 : 3
        enabled: !self.readOnly && convert.fiat
        contentItem: RowLayout {
            spacing: 4
            Label {
                color: unit_label.enabled && unit_label.hovered ? '#00DD6E' : '#00B45A'
                font.pixelSize: 16
                font.weight: 500
                text: {
                    if (convert.fiat) {
                        if (self.fiat) {
                            return self.account.session.settings.pricing.currency
                        } else {
                            return (self.account.network.liquid ? 'L-' : '') + self.unit
                        }
                    } else {
                        return convert.asset?.data?.ticker ?? ''
                    }
                }
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/caret-down.svg'
                visible: !self.readOnly && unit_label.enabled
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
                enabled: convert.fiat
                hideIcon: true
                text: self.account.session.settings.pricing.currency
                onClicked: {
                    unit_menu.close()
                    self.fiat = true
                }
            }
            Repeater {
                model: self.units
                delegate: GMenu.Item {
                    hideIcon: true
                    text: (self.account.network.liquid ? 'L-' : '') + modelData
                    onClicked: {
                        unit_menu.close()
                        self.fiat = false
                        self.unit = modelData
                    }
                }
            }
        }    }
    Label {
        id: second_label
        anchors.right: parent.right
        anchors.rightMargin: self.rightPadding
        anchors.top: parent.baseline
        anchors.topMargin: 8
        text: !self.fiat ? convert.fiatLabel : convert.unitLabel
        color: '#FFF'
        opacity: 0.4
        font.pixelSize: 12
        font.weight: 500
        visible: convert.fiat
        TapHandler {
            enabled: !self.readOnly
            cursorShape: Qt.ArrowCursor
            onTapped: self.fiat = !self.fiat
        }
    }
}
