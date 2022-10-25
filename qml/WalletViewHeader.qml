import Blockstream.Green.Core 0.1
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
    property int currentView: 0
    readonly property bool archived: self.currentAccount ? self.currentAccount.hidden : false

    onCurrentViewChanged: updateCurrentView()

    function updateCurrentView() {
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
        spacing: constants.s0
        AlertView {
            id: alert_view
            alert: overview_alert
        }
        GPane {
            Layout.fillWidth: true
            padding: 0
            leftPadding: -8
            focusPolicy: Qt.ClickFocus
            contentItem: RowLayout {
                spacing: 0
                Control {
                    Layout.maximumWidth: self.width / 3
                    padding: 2
                    leftPadding: 8
                    background: null
                    contentItem: RowLayout {
                        spacing: 8
                        Image {
                            fillMode: Image.PreserveAspectFit
                            sourceSize.height: 24
                            sourceSize.width: 24
                            source: iconFor(self.wallet)
                        }
                        Loader {
                            active: wallet.persisted
                            visible: active
                            Layout.fillWidth: true
                            sourceComponent: EditableLabel {
                                leftPadding: 8
                                rightPadding: 8
                                font.pixelSize: 18
                                font.styleName: 'Medium'
                                text: wallet.name
                                onEdited: {
                                    if (wallet.rename(text, activeFocus)) {
                                        Analytics.recordEvent('wallet_rename')
                                    }
                                }
                            }
                        }
                        Loader {
                            Layout.minimumHeight: 42
                            active: !wallet.persisted
                            visible: active
                            sourceComponent: Label {
                                verticalAlignment: Qt.AlignVCenter
                                text: wallet.name
                                font.pixelSize: 18
                                font.styleName: 'Medium'
                            }
                        }
                    }
                }
                Image {
                    fillMode: Image.PreserveAspectFit
                    sourceSize.height: 16
                    sourceSize.width: 16
                    source: 'qrc:/svg/right.svg'
                    Layout.alignment: Qt.AlignVCenter
                }
                Control {
                    Layout.maximumWidth: self.width / 2
                    padding: 2
                    rightPadding: account_type_badge.visible ? 24 : 16
                    background: null
                    contentItem: RowLayout {
                        spacing: account_type_badge.visible ? 8 : 0
                        Loader {
                            active: !wallet.watchOnly
                            visible: active
                            Layout.fillWidth: true
                            sourceComponent: EditableLabel {
                                leftPadding: 8
                                rightPadding: 8
                                font.pixelSize: 18
                                font.styleName: 'Regular'
                                text: accountName(self.currentAccount)
                                enabled: !self.wallet.watchOnly && self.currentAccount && !self.wallet.locked
                                onEdited: {
                                    if (enabled && self.currentAccount) {
                                        renameAccount(self.currentAccount, text, activeFocus)
                                    }
                                }
                            }
                        }
                        Loader {
                            Layout.minimumHeight: 42
                            active: !wallet.device && wallet.watchOnly
                            visible: active
                            sourceComponent: Label {
                                verticalAlignment: Qt.AlignVCenter
                                text: accountName(self.currentAccount)
                                font.pixelSize: 18
                                font.styleName: 'Medium'
                            }
                        }
                        AccountTypeBadge {
                            id: account_type_badge
                            account: self.currentAccount
                        }
                        Label {
                            visible: self.archived
                            font.pixelSize: 10
                            font.capitalization: Font.AllUppercase
                            leftPadding: 8
                            rightPadding: 8
                            topPadding: 4
                            bottomPadding: 4
                            color: 'white'
                            background: Rectangle {
                                color: constants.c400
                                radius: 4
                            }
                            text: qsTrId('id_archived')
                        }
                    }
                }
                HSpacer {
                }
                RowLayout {
                    Layout.fillWidth: false
                    spacing: constants.s1
                    ToolButton {
                        visible: (wallet.events && !!wallet.events.twofactor_reset && wallet.events.twofactor_reset.is_active) || !fiatRateAvailable
                        icon.source: 'qrc:/svg/notifications_2.svg'
                        icon.color: 'transparent'
                        icon.width: 16
                        icon.height: 16
                        onClicked: notifications_drawer.open()
                    }
                    ToolButton {
                        icon.source: 'qrc:/svg/refresh.svg'
                        flat: true
                        action: self.refreshAction
                        ToolTip.text: qsTrId('id_refresh')
                        ToolTip.delay: 300
                        ToolTip.visible: hovered
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
                        icon.source: 'qrc:/svg/logout.svg'
                        flat: true
                        action: self.disconnectAction
                        ToolTip.text: qsTrId('id_logout')
                        ToolTip.delay: 300
                        ToolTip.visible: hovered
                    }
                }
            }
        }
        GPane {
            Layout.fillWidth: true
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
                    text: qsTrId('id_overview')
                    onClicked: checked = true
                }

                TabButton {
                    id: assets_toolbar_button
                    ButtonGroup.group: button_group
                    enabled: self.wallet.network.liquid
                    visible: enabled
                    text: qsTrId('id_assets')
                    onClicked: checked = true
                }

                TabButton {
                    id: transactions_toolbar_button
                    checked: !self.wallet.network.liquid
                    ButtonGroup.group: button_group
                    text: qsTrId('id_transactions')
                    onClicked: checked = true
                }

                TabButton {
                    ButtonGroup.group: button_group
                    text: qsTrId('id_addresses')
                    enabled: !self.wallet.watchOnly
                    onClicked: checked = true
                }

                TabButton {
                    ButtonGroup.group: button_group
                    text: qsTrId('id_coins')
                    enabled: !self.wallet.watchOnly
                    onClicked: checked = true
                }

                HSpacer { }

                GButton {
                    id: send_button
                    Layout.alignment: Qt.AlignRight
                    large: true
                    enabled: !self.archived && !self.wallet.watchOnly && !self.wallet.locked && self.currentAccount
                    hoverEnabled: true
                    text: qsTrId('id_send')
                    icon.source: 'qrc:/svg/send.svg'
                    onClicked: {
                        if (self.currentAccount.balance > 0) {
                            send_dialog.createObject(window, { account: self.currentAccount }).open()
                        }
                        else {
                            message_dialog.createObject(window).open()
                        }
                    }
                    ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                    ToolTip.text: qsTrId('id_insufficient_lbtc_to_send_a')
                    ToolTip.visible: hovered && !enabled
                }

                GButton {
                    Layout.alignment: Qt.AlignRight
                    large: true
                    enabled: !self.archived && !wallet.locked && self.currentAccount
                    text: qsTrId('id_receive')
                    icon.source: 'qrc:/svg/receive.svg'
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
            width: 350
            title: qsTrId('id_warning')
            message: self.wallet.network.liquid ? qsTrId('id_insufficient_lbtc_to_send_a') : qsTrId('id_you_have_no_coins_to_send')
            actions: [
                Action {
                    text: qsTrId('id_cancel')
                    onTriggered: dialog.reject()
                },
                Action {
                    property bool highlighted: true
                    text: self.wallet.network.liquid ? qsTrId('id_learn_more') : qsTrId('id_receive')
                    onTriggered: {
                        dialog.reject()
                        if (self.wallet.network.liquid) {
                            Qt.openUrlExternally('https://help.blockstream.com/hc/en-us/articles/900000630846-How-do-I-get-Liquid-Bitcoin-L-BTC-')
                        } else {
                            receive_dialog.createObject(window, { account: self.currentAccount }).open()
                        }
                    }
                }
            ]
        }
    }

    component TabButton: Button {
        id: tab_button
        padding: 16
        text: ToolTip.text
        background: Rectangle {
            color: checked ? constants.c400 : hovered ? constants.c600 : 'transparent'
            radius: 4
        }
        contentItem: Label {
            text: tab_button.text
            font.pixelSize: 14
            font.bold: false
        }
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

    property Action refreshAction: Action {
        enabled: wallet.activities.length === 0
        onTriggered: wallet.reload(true)
    }
}
