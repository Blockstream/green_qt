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
            leftPadding: -8
            focusPolicy: Qt.ClickFocus
            contentItem: RowLayout {
                spacing: 16
                Control {
                    id: wallet_pill
                    padding: 2
                    rightPadding: 16
                    leftPadding: 8
                    background: Rectangle {
                        color: constants.c700
                        radius: height / 2
                        border.width: 1
                        border.color: constants.c600
                        visible: wallet_pill.hovered
                    }
                    contentItem: RowLayout {
                        spacing: 8
                        Image {
                            fillMode: Image.PreserveAspectFit
                            sourceSize.height: 32
                            sourceSize.width: 32
                            source: icons[self.wallet.network.key]
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
                            Layout.minimumHeight: 42
                            active: !wallet.device && wallet.watchOnly
                            sourceComponent: Label {
                                verticalAlignment: Qt.AlignVCenter
                                text: walletName(wallet)
                                font.pixelSize: 24
                                font.styleName: 'Medium'
                            }
                        }
                        Loader {
                            Layout.minimumHeight: 42
                            active: wallet.device
                            sourceComponent: Label {
                                verticalAlignment: Qt.AlignVCenter
                                text: wallet.device.name
                                font.pixelSize: 24
                                font.styleName: 'Medium'
                            }
                        }
                        Image {
                            fillMode: Image.PreserveAspectFit
                            sourceSize.height: 24
                            sourceSize.width: 24
                            source: wallet.network.electrum ? 'qrc:/svg/key.svg' : 'qrc:/svg/multi-sig.svg'
                        }
                        Loader {
                            visible: wallet.device
                            sourceComponent: DeviceImage {
                                device: wallet.device
                                sourceSize.height: 24

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
                    }
                }
                Image {
                    fillMode: Image.PreserveAspectFit
                    sourceSize.height: 24
                    sourceSize.width: 24
                    source: 'qrc:/svg/right.svg'
                }
                Control {
                    id: account_pill
                    padding: 2
                    rightPadding: account_type_badge.visible ? 24 : 16
                    leftPadding: 16
                    background: Rectangle {
                        color: constants.c700
                        radius: height / 2
                        border.width: 1
                        border.color: constants.c600
                        visible: account_pill.hovered
                    }
                    contentItem: RowLayout {
                        spacing: account_type_badge.visible ? 8 : 0
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
                        Loader {
                            Layout.minimumHeight: 42
                            active: !wallet.device && wallet.watchOnly
                            sourceComponent: Label {
                                verticalAlignment: Qt.AlignVCenter
                                text: accountName(self.currentAccount)
                                font.pixelSize: 24
                                font.styleName: 'Medium'
                            }
                        }
                        AccountTypeBadge {
                            id: account_type_badge
                            account: self.currentAccount
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
                    ToolTip.text: qsTrId('id_coins')
                    enabled: !self.wallet.watchOnly && !self.wallet.network.electrum
                    onClicked: checked = true
                }

                HSpacer { }

                GButton {
                    id: send_button
                    Layout.alignment: Qt.AlignRight
                    large: true
                    enabled: !self.wallet.watchOnly && !self.wallet.locked && self.currentAccount
                    hoverEnabled: true
                    text: qsTrId('id_send')
                    onClicked: {
                        if (self.currentAccount.balance > 0) {
                            send_dialog.createObject(window, { account: self.currentAccount }).open()
                        }
                        else {
                            message_dialog.createObject(window, {
                                account: self.currentAccount,
                                title: qsTrId('id_warning'), message: self.wallet.network.liquid ? qsTrId('id_insufficient_lbtc_to_send_a') : qsTrId('You have no coins to send. Generate an address to receive some bitcoins.')
                            }).open()
                        }
                    }
                    ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                    ToolTip.text: qsTrId('id_insufficient_lbtc_to_send_a')
                    ToolTip.visible: hovered && !enabled
                }

                GButton {
                    Layout.alignment: Qt.AlignRight
                    large: true
                    enabled: !wallet.locked && self.currentAccount
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

    Component {
        id: message_dialog
        MessageDialog {
            id: dialog
            wallet: self.wallet
            width: 300
            actions: [
                Action {
                    text: qsTrId('id_cancel')
                    onTriggered: {
                        dialog.reject()
                    }
                },
                Action {
                    text: qsTrId('id_receive')
                    onTriggered: {
                        dialog.reject()
                        receive_dialog.createObject(window, { account: self.currentAccount }).open()
                    }
                }
            ]
        }
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
