import Blockstream.Green.Core
import Blockstream.Green
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Shapes
import QtQml

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

MainPageHeader {
    required property Context context
    required property Wallet wallet
    required property Account currentAccount
    readonly property bool archived: self.currentAccount ? self.currentAccount.hidden : false
    property Component toobar

    id: self

    topPadding: 0
    leftPadding: 0
    rightPadding: 0

    component HPane: GPane {
        padding: 4
        Layout.fillWidth: true
        leftPadding: constants.p3
        rightPadding: constants.p3
        background: null
    }

    contentItem: ColumnLayout {
        spacing: 0
        AlertView {
            id: alert_view
            alert: overview_alert
        }
        HPane {
            leftPadding: constants.p3 - 8
            contentItem: RowLayout {
                spacing: 0
                Control {
                    Layout.maximumWidth: self.width / 3
                    padding: 2
                    leftPadding: 0
                    background: null
                    contentItem: RowLayout {
                        spacing: 8
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
                    rightPadding: 16
                    background: null
                    contentItem: RowLayout {
                        spacing: 0
                        Loader {
                            active: !self.context.watchonly
                            visible: active
                            Layout.fillWidth: true
                            sourceComponent: EditableLabel {
                                leftPadding: 8
                                rightPadding: 8
                                font.pixelSize: 18
                                font.styleName: 'Regular'
                                text: UtilJS.accountName(self.currentAccount)
                                enabled: !self.context.watchonly && self.currentAccount && !self.wallet.locked
                                onEdited: (text) => {
                                    if (enabled && self.currentAccount) {
                                        if (controller.setAccountName(self.currentAccount, text, activeFocus)) {
                                            Analytics.recordEvent('account_rename', AnalyticsJS.segmentationSubAccount(self.currentAccount))
                                        }
                                    }
                                }
                            }
                        }
                        Loader {
                            Layout.minimumHeight: 42
                            active: !wallet.context.device && self.context.watchonly
                            visible: active
                            sourceComponent: Label {
                                verticalAlignment: Qt.AlignVCenter
                                text: UtilJS.accountName(self.currentAccount)
                                font.pixelSize: 18
                                font.styleName: 'Medium'
                            }
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
                        visible: (wallet.context.events.twofactor_reset?.is_active ?? false) || !fiatRateAvailable
                        icon.source: 'qrc:/svg/notifications_2.svg'
                        icon.color: 'transparent'
                        icon.width: 16
                        icon.height: 16
                        onClicked: notifications_drawer.open()
                    }
                    ToolButton {
                        visible: false
                        icon.source: 'qrc:/svg/refresh.svg'
                        flat: true
                        action: self.refreshAction
                        ToolTip.text: qsTrId('id_refresh')
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
                    ToolButton {
                        icon.source: 'qrc:/svg/gearFill.svg'
                        flat: true
                        action: self.settingsAction
                        ToolTip.text: qsTrId('id_settings')
                        ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                        ToolTip.visible: hovered
                    }
                }
            }
        }
        HPane {
            visible: false
            contentItem: RowLayout {
                spacing: 8
                TotalBalanceCard {
                    context: self.context
                }
                HSpacer {
                }
            }
        }
        HPane {
            contentItem: RowLayout {
                ToolButton {
                    icon.source: 'qrc:/svg/new.svg'
                    flat: true
                    enabled: !self.context.watchonly
                    onClicked: openCreateDialog()
                    ToolTip.text: qsTrId('id_add_new_account')
                    ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                    ToolTip.visible: hovered
                }
                ToolButton {
                    icon.source: 'qrc:/svg/archived.svg'
                    flat: true
//                        enabled: !self.archived && !wallet.locked && self.currentAccount
                    enabled: archive_list_model.count > 0
                    onClicked: navigation.set({ archive: !checked })
                    checked: navigation.param?.archive ?? false
//                        onClicked: navigation.set({ flow: 'receive' })
//                        ToolTip.text: qsTrId('id_receive')
//                        ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
//                        ToolTip.visible: hovered
                }
                HSpacer {
                }
                GPane {
                    id: tabbar
                    padding: 0
                    background: null

    //                    Rectangle {
    //                    border.width: 0.5
    //                    border.color: Qt.lighter(constants.c500)
    //                    color: tabbar.hovered ? Qt.lighter(constants.c500) : 'transparent'
    //                    radius: 7
    //                    opacity: 0.5
    //                    Behavior on color {
    //                        SequentialAnimation {
    //                            PauseAnimation {
    //                                duration: 200
    //                            }
    //                            ColorAnimation {
    //                                duration: 300
    //                            }
    //                        }
    //                    }
    //                }
                    contentItem: RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        spacing: 4
                        TabButton {
                            checked: navigation.param.view === 'overview'
                            enabled: self.wallet.network.liquid
                            visible: enabled
                            text: qsTrId('id_overview')
                            onClicked: navigation.set({ view: 'overview' })
                        }
    //                    TabSeparator {
    //                        visible: self.wallet.network.liquid
    //                    }
                        TabButton {
                            checked: navigation.param.view === 'assets'
                            enabled: self.context.network.liquid
                            visible: enabled
                            text: qsTrId('id_assets')
                            onClicked: navigation.set({ view: 'assets' })
                        }
    //                    TabSeparator {
    //                        visible: self.wallet.network.liquid
    //                    }
                        TabButton {
                            checked: navigation.param.view === 'transactions'
                            text: qsTrId('id_transactions')
                            onClicked: navigation.set({ view: 'transactions' })
                        }
    //                    TabSeparator {
    //                    }
                        TabButton {
                            checked: navigation.param.view === 'addresses'
                            text: qsTrId('id_addresses')
                            enabled: !self.context.watchonly
                            onClicked: navigation.set({ view: 'addresses' })
                        }
    //                    TabSeparator {
    //                    }
                        TabButton {
                            checked: navigation.param.view === 'coins'
                            text: qsTrId('id_coins')
                            enabled: !self.context.watchonly
                            onClicked: navigation.set({ view: 'coins' })
                        }
                    }
                }
                HSpacer {
                }
    //            Loader {
    //                sourceComponent: self.toobar
    //            }
                ToolButton {
                    icon.source: 'qrc:/svg/send.svg'
                    flat: true
                    enabled: !self.archived && !self.context.watchonly && !self.wallet.locked && self.currentAccount
                    onClicked: {
                        if (self.currentAccount.balance > 0) {
                            onClicked: navigation.set({ flow: 'send' })
                        }
                        else {
                            message_dialog.createObject(window).open()
                        }
                    }
                    ToolTip.text: qsTrId('id_send')
                    ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                    ToolTip.visible: hovered
                }
                ToolButton {
                    icon.source: 'qrc:/svg/receive.svg'
                    flat: true
                    enabled: !self.archived && !wallet.locked && self.currentAccount
                    onClicked: navigation.set({ flow: 'receive' })
                    ToolTip.text: qsTrId('id_receive')
                    ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                    ToolTip.visible: hovered
                }
            }
        }


//            GButton {
//                id: send_button
//                Layout.alignment: Qt.AlignRight
//                large: true
//                enabled: !self.archived && !self.context.watchonly && !self.wallet.locked && self.currentAccount
//                hoverEnabled: true
//                padding: 4
//                font.bold: false
//                icon.width: 24
//                icon.height: 24
//                text: qsTrId('id_send')
//                icon.source: 'qrc:/svg/send.svg'
//                background: Rectangle {
//                    visible: send_button.hovered
//                    color: Qt.lighter(constants.c500)
//                    opacity: 0.2
//                    radius: 4
//                }

//                onClicked: {
//                    if (self.currentAccount.balance > 0) {
//                        onClicked: navigation.set({ flow: 'send' })
//                    }
//                    else {
//                        message_dialog.createObject(window).open()
//                    }
//                }
//                ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
//                ToolTip.text: qsTrId('id_insufficient_lbtc_to_send_a')
//                ToolTip.visible: hovered && !enabled
//            }
//            GButton {
//                id: receive_button
//                background: Rectangle {
//                    visible: receive_button.hovered
//                    color: Qt.lighter(constants.c500)
//                    opacity: 0.2
//                    radius: 4
//                }

//                Layout.alignment: Qt.AlignRight
//                large: true
//                enabled: !self.archived && !wallet.locked && self.currentAccount
//                text: qsTrId('id_receive')
//                font.bold: false
//                icon.width: 24
//                icon.height: 24
//                icon.source: 'qrc:/svg/receive.svg'
//                onClicked: navigation.set({ flow: 'receive' })
//            }
    }

    Loader2 {
        active: navigation.param.flow === 'send'
        sourceComponent: SendDialog {
            visible: true
            account: self.currentAccount
            onRejected: navigation.pop()
            onClosed: destroy()
        }
    }

    Loader2 {
        active: navigation.param.flow === 'receive'
        sourceComponent: ReceiveDialog {
            visible: true
            account: self.currentAccount
            onRejected: navigation.pop()
            onClosed: destroy()
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
        Layout.minimumWidth: 80
        padding: 0
        verticalPadding: 0
        topPadding: 4
        bottomPadding: 4
        leftPadding: 4
        rightPadding: 4
        text: ToolTip.text
//        leftInset: 3
//        rightInset: 3
//        topInset: 3
//        bottomInset: 3
        background: Rectangle {
            radius: height / 2
            //color: checked ? Qt.lighter(constants.c500) : 'transparent'
            color: Qt.rgba(1, 1, 1, hovered ? 0.1 : 0)
            border.width: checked ? 0.5 : 0
            border.color: 'white'
        }
        contentItem: Label {
            padding: 8
            text: tab_button.text
            opacity: tab_button.checked ? 1 : 0.5
            font.pixelSize: 16
            font.bold: false
            horizontalAlignment: Label.AlignHCenter
        }
    }

    component TabSeparator: Rectangle {
        id: separator
        Layout.alignment: Qt.AlignCenter
        implicitWidth: 1
        implicitHeight: 20
        color: Qt.lighter(constants.c500)
        opacity: {
            let button
            let left
            let right
            let sep
            for (let i = 0; i < parent.children.length; i++) {
                const child = parent.children[i]
                if (child === separator) {
                    left = button
                } else if (child.checked !== undefined && child.visible) {
                    button = child
                    if (left && !right) {
                        right = button
                        break;
                    }
                }
            }
            return left && left.checked || right && right.checked ? 0 : 1
        }
    }

    property Action disconnectAction: Action {
        onTriggered: {
            self.wallet.disconnect()
        }
    }

    property Action settingsAction: Action {
        enabled: {
            if (self.context.watchonly) return false
            if (self.wallet.network.electrum) return true
            return !!self.wallet.context.settings.pricing
        }
        onTriggered: navigation.set({ settings: true })
    }

    property Action refreshAction: Action {
        // TODO reload from be done from a controller, not from wallet or context
        enabled: false
    }

    component TotalBalanceCard: GPane {
        required property Context context
        readonly property var balance: {
            let r = 0
            for (let i = 0; i < self.context.accounts.length; i++) {
                const account = self.context.accounts[i]
                r += account.balance
            }
            return r
        }

        Layout.minimumHeight: 64
        Layout.minimumWidth: 250
        id: self
        background: Rectangle {
            visible: false
            radius: 5
            border.width: 0.5
            border.color: Qt.alpha(constants.c500, 1)
            color: Qt.alpha(constants.c500, 0.25)
        }
        contentItem: ColumnLayout {
            SectionLabel {
                text: qsTrId('id_total_balance')
            }
            VSpacer {
            }
            Label {
                text: formatFiat(self.balance)
                font.pixelSize: 12
                font.weight: 400
            }
            Label {
                text: formatAmount(self.balance)
                font.pixelSize: 16
                font.weight: 600
            }
        }
    }

}
