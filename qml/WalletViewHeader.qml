import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.14
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12
import QtQml 2.15

MainPageHeader {
    required property Wallet wallet
    required property Account currentAccount
    property bool showAccounts: true
    property var currentView: 0

    onCurrentViewChanged: {
        for (let i = button_group.buttons.length; i >= 0; --i) {
            let child = button_group.buttons[i]
            if (i === currentView) button_group.buttons[button_group.buttons.length-i-1].checked = true
        }
    }

    signal viewSelected(var viewIndex)

    id: self
    background: Rectangle {
        color: constants.c800
    }
    contentItem: ColumnLayout {
        spacing: constants.p1
        GPane {
            Layout.fillWidth: true
            background: null
            padding: 0
            leftPadding: wallet.device || wallet.watchOnly ? 0 : -8
            focusPolicy: Qt.ClickFocus
            contentItem: RowLayout {
                spacing: 16
                Loader {
                    visible: wallet.device
                    sourceComponent: DeviceImage {
                        device: wallet.device
                        sourceSize.height: 32

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (wallet.device.type === Device.BlockstreamJade) {
                                    navigation.go(`/jade/${wallet.device.uuid}`)
                                } else if (wallet.device.vendor === Device.Ledger) {
                                    navigation.go(`/ledger/${wallet.device.uuid}`)
                                }
                            }
                        }
                    }
                }
                Loader {
                    active: !wallet.device && !wallet.watchOnly
                    visible: active
                    sourceComponent: EditableLabel {
                        leftPadding: 8
                        rightPadding: 8
                        font.pixelSize: 22
                        font.styleName: 'Medium'
                        text: wallet.name
                        onEdited: {
                            wallet.rename(text, activeFocus)
                        }
                    }
                }
                Loader {
                    active: !wallet.device && wallet.watchOnly
                    sourceComponent: Label {
                        text: walletName(wallet)
                        font.pixelSize: 24
                        font.styleName: 'Medium'
                    }
                }
                Loader {
                    active: wallet.device
                    sourceComponent: Label {
                        text: wallet.device.name
                        font.pixelSize: 24
                        font.styleName: 'Medium'
                    }
                }
                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: constants.p2
                }
                Loader {
                    active: !wallet.watchOnly
                    visible: active
                    sourceComponent: EditableLabel {
                        leftPadding: 8
                        rightPadding: 8
                        font.pixelSize: 22
                        font.styleName: 'Regular'
                        text: accountName(self.currentAccount)
                        enabled: !self.wallet.watchOnly && self.currentAccount && !self.wallet.locked
                        onEdited: {
                            if (enabled && self.currentAccount) {
                                self.currentAccount.rename(text, activeFocus)
                            }
                        }
                    }
                }
                HSpacer {
                }
                ToolButton {
                    visible: (wallet.events && !!wallet.events.twofactor_reset && wallet.events.twofactor_reset.is_active) || !fiatRateAvailable
                    icon.source: 'qrc:/svg/notifications_2.svg'
                    icon.color: 'transparent'
                    icon.width: 16
                    icon.height: 16
                    onClicked: notifications_drawer.open()
                }
                ToolButton {
                    icon.source: 'qrc:/svg/gearFill.svg'
                    flat: true
                    action: self.settingsAction
                    ToolTip.text: qsTrId('id_settings')
                    ToolTip.delay: 300
                    ToolTip.visible: hovered
                }
                ToolButton {
                    visible: !self.wallet.device
                    icon.source: 'qrc:/svg/logout.svg'
                    flat: true
                    action: self.disconnectAction
                    ToolTip.text: 'Logout'
                    ToolTip.delay: 300
                    ToolTip.visible: hovered
                }
            }
        }
        GPane {
            Layout.fillWidth: true
            background: null
            padding: 0
            focusPolicy: Qt.ClickFocus
            contentItem: RowLayout {
                id: toolbar
                Layout.fillWidth: true
                Layout.fillHeight: false
                spacing: constants.p1

                ButtonGroup {
                    id: button_group
                    onCheckedButtonChanged: {
                        let index = -1
                        let size = button_group.buttons.length
                        if (!self.wallet.network.liquid) size -= 2 // if account is not liquid ignore the first two buttons
                        for (let i = 0; i < size; ++i) {
                            let child = button_group.buttons[i]
                            if (child.enabled && child.checked) index = button_group.buttons.length-i-1
                        }
                        if (index>-1) self.viewSelected(index)
                    }
                }

                ToolButton {
                    id: side_bar_button
                    visible: false
                    checkable: true
                    icon.source: "qrc:/svg/sidebar.svg"
                    icon.width: 16
                    icon.height: 16
                    checked: self.showAccounts
                    onClicked: self.showAccounts = !self.showAccounts
                }

                TabButton {
                    checked: self.wallet.network.liquid
                    ButtonGroup.group: button_group
                    enabled: self.wallet.network.liquid
                    visible: enabled
                    icon.source: "qrc:/svg/overview.svg"
                    ToolTip.text: qsTrId('id_overview')
                    onClicked: checked = true
                }

                TabButton {
                    id: assets_toolbar_button
                    ButtonGroup.group: button_group
                    enabled: self.wallet.network.liquid
                    visible: enabled
                    icon.source: "qrc:/svg/assets.svg"
                    ToolTip.text: qsTrId('id_assets')
                    onClicked: checked = true
                }

                TabButton {
                    id: transactions_toolbar_button
                    checked: !self.wallet.network.liquid
                    ButtonGroup.group: button_group
                    icon.source: "qrc:/svg/transactions.svg"
                    ToolTip.text: qsTrId('id_transactions')
                    onClicked: checked = true
                }

                TabButton {
                    ButtonGroup.group: button_group
                    icon.source: "qrc:/svg/addresses.svg"
                    ToolTip.text: qsTrId('id_addresses')
                    enabled: !self.wallet.watchOnly && !self.wallet.network.electrum
                    onClicked: checked = true
                }

                TabButton {
                    ButtonGroup.group: button_group
                    icon.source: "qrc:/svg/coins.svg"
                    ToolTip.text: qsTrId('Coins')
                    enabled: !self.wallet.watchOnly && !self.wallet.network.electrum
                    onClicked: checked = true
                }

                HSpacer { }

                GButton {
                    id: send_button
                    Layout.alignment: Qt.AlignRight
                    large: true
                    enabled: !self.wallet.watchOnly && !self.wallet.locked && self.currentAccount && self.currentAccount.balance > 0
                    hoverEnabled: true
                    text: qsTrId('id_send')
                    onClicked: send_dialog.createObject(window, { account: self.currentAccount }).open()
                    ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                    ToolTip.text: qsTrId('id_insufficient_lbtc_to_send_a')
                    ToolTip.visible: hovered && !enabled
                }

                GButton {
                    Layout.alignment: Qt.AlignRight
                    large: true
                    enabled: !wallet.locked
                    text: qsTrId('id_receive')
                    onClicked: receive_dialog.createObject(window, { account: self.currentAccount }).open()
                }
            }
        }
    }

    Component {
        id: send_dialog
        SendDialog { }
    }

    Component {
        id: receive_dialog
        ReceiveDialog { }
    }

    component TabButton: ToolButton {
        icon.width: constants.p4
        icon.height: constants.p4
        icon.color: Qt.rgba(1, 1, 1, enabled ? 1 : 0.5)
        padding: 4
        background: Rectangle {
            color: parent.checked ? constants.c400 : parent.hovered ? constants.c600 : constants.c700
            radius: 4
        }
        ToolTip.delay: 300
        ToolTip.visible: hovered
    }

    property Action disconnectAction: Action {
        onTriggered: {
            navigation.go(`/${wallet.network.key}`)
            self.wallet.disconnect()
        }
    }

    property Action settingsAction: Action {
        enabled: settings_dialog.enabled
        onTriggered: navigation.go(settings_dialog.location)
    }
}
