import Blockstream.Green.Core
import Blockstream.Green
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQml

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

MainPageHeader {
    required property Wallet wallet
    required property Account currentAccount
    readonly property bool archived: self.currentAccount ? self.currentAccount.hidden : false

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
                            source: UtilJS.iconFor(self.wallet)
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
                                onEdited: (text, activeFocus) => {
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
                                text: UtilJS.accountName(self.currentAccount)
                                enabled: !self.wallet.watchOnly && self.currentAccount && !self.wallet.locked
                                onEdited: (text) => {
                                    if (enabled && self.currentAccount) {
                                        if (self.currentAccount.rename(text, activeFocus)) {
                                            Analytics.recordEvent('account_rename', AnalyticsJS.segmentationSubAccount(self.currentAccount))
                                        }
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
                                text: UtilJS.accountName(self.currentAccount)
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
                Layout.fillWidth: true
                Layout.fillHeight: false
                spacing: constants.p1
                TabButton {
                    checked: navigation.param.view === 'overview'
                    enabled: self.wallet.network.liquid
                    visible: enabled
                    text: qsTrId('id_overview')
                    onClicked: navigation.set({ view: 'overview' })
                }

                TabButton {
                    checked: navigation.param.view === 'assets'
                    enabled: self.wallet.network.liquid
                    visible: enabled
                    text: qsTrId('id_assets')
                    onClicked: navigation.set({ view: 'assets' })
                }

                TabButton {
                    checked: navigation.param.view === 'transactions'
                    text: qsTrId('id_transactions')
                    onClicked: navigation.set({ view: 'transactions' })
                }

                TabButton {
                    checked: navigation.param.view === 'addresses'
                    text: qsTrId('id_addresses')
                    enabled: !self.wallet.watchOnly
                    onClicked: navigation.set({ view: 'addresses' })
                }

                TabButton {
                    checked: navigation.param.view === 'coins'
                    text: qsTrId('id_coins')
                    enabled: !self.wallet.watchOnly
                    onClicked: navigation.set({ view: 'coins' })
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
                            onClicked: navigation.set({ flow: 'send' })
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
                    onClicked: navigation.set({ flow: 'receive' })
                }
            }
        }
    }

    Loader2 {
        active: navigation.param.flow === 'send'
        sourceComponent: SendDialog {
            visible: true
            account: self.currentAccount
            onRejected: navigation.pop()
        }
    }

    Loader2 {
        active: navigation.param.flow === 'receive'
        sourceComponent: ReceiveDialog {
            visible: true
            account: self.currentAccount
            onRejected: navigation.pop()
        }
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
                            navigation.set({ flow: 'receive' })
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
            self.wallet.disconnect()
        }
    }

    property Action settingsAction: Action {
        enabled: {
            if (self.wallet.watchOnly) return false
            if (self.wallet.network.electrum) return true
            return !!self.wallet.settings.pricing
        }
        onTriggered: navigation.set({ settings: true })
    }

    property Action refreshAction: Action {
        enabled: wallet.activities.length === 0
        onTriggered: wallet.reload(true)
    }
}
