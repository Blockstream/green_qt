import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

RowLayout {
    required property Context context

    readonly property var amp0Accounts: UtilJS.accounts(self.context).filter(account => account.amp0)
    readonly property var amp2Accounts: UtilJS.accounts(self.context).filter(account => account.amp2)

    readonly property bool canCreateAmp0Account: !self.context?.watchonly
    readonly property bool canCreateAmp2Account: !self.context?.mainnet && !self.context?.watchonly && !self.context?.device && self.context?.deployment === 'testnet'
    readonly property bool canCreateAmpAccount: (self.context.mainnet && self.canCreateAmp0Account) || self.canCreateAmp2Account

    readonly property bool hasVisibleAmpAccounts: self.amp0Accounts.length > 0 || self.amp2Accounts.length > 0
    readonly property bool showCreateAccountButton: !self.hasVisibleAmpAccounts && self.canCreateAmpAccount

    readonly property string primaryCreateType: self.context.mainnet ? '2of2_no_recovery' : 'amp2'
    readonly property bool creatingAccount: !(controller.monitor?.idle ?? true)
    property string creatingType: ''

    function createAmpAccount(type) {
        if (self.creatingAccount) return

        error_badge.clear()
        self.creatingType = type

        const network = type === 'amp2'
            ? NetworkManager.network('electrum-testnet-liquid')
            : NetworkManager.networkWithServerType(self.context.deployment, self.context.mainnet ? 'liquid' : 'testnet-liquid', 'green')
        controller.network = network
        controller.asset = self.context.getOrCreateAsset(network.policyAsset)
        controller.type = type
        controller.create()
    }

    id: self
    spacing: 20
    visible: {
        if (self.context.mainnet) return self.amp0Accounts.length > 0 || self.canCreateAmp0Account
        return self.hasVisibleAmpAccounts || self.canCreateAmp2Account
    }

    CreateAccountController {
        id: controller
        context: self.context
        onCreated: {
            self.creatingType = ''
            error_badge.clear()
        }
        onFailed: (error) => {
            self.creatingType = ''
            error_badge.raise(error || "The action can't be completed")
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.alignment: Qt.AlignTop
        spacing: 2

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Label {
                color: '#FFFFFF'
                font.pixelSize: 14
                font.weight: 600
                text: qsTrId('id_amp_account')
            }

            LinkButton {
                external: true
                font.pixelSize: 12
                text: qsTrId('id_learn_more')
                onClicked: Qt.openUrlExternally('https://help.blockstream.com/blockstream-app/use-liquid-bitcoin/generate-amp-id')
            }
        }

        Label {
            Layout.fillWidth: true
            color: '#6F6F6F'
            font.pixelSize: 13
            font.weight: 400
            text: self.hasVisibleAmpAccounts
                ? 'Share your AMP ID with your security token issuer to receive authorization to move funds.'
                : 'AMP accounts allow you to send, receive and store managed assets issued on the Liquid Network.'
            wrapMode: Label.Wrap
        }
    }

    ColumnLayout {
        Layout.alignment: self.showCreateAccountButton ? Qt.AlignVCenter | Qt.AlignRight : Qt.AlignTop | Qt.AlignRight
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        spacing: 8

        AmpCreateLinkButton {
            Layout.alignment: Qt.AlignRight
            visible: self.showCreateAccountButton
            busy: self.creatingType === self.primaryCreateType
            enabled: !self.creatingAccount
            text: self.creatingType === self.primaryCreateType ? 'Creating AMP Account...' : 'Create AMP Account'
            onClicked: self.createAmpAccount(self.primaryCreateType)
        }

        // AMP Section
        Repeater {
            model: self.context.mainnet ? self.amp0Accounts : self.amp2Accounts
            delegate: AmpAccountCard {
                required property Account modelData
                Layout.fillWidth: true
                title: UtilJS.accountName(modelData)
                subtitle: 'ID: ' + UtilJS.ampId(modelData)
                copyText: UtilJS.ampId(modelData)
            }
        }

        AmpMissingAccountCard {
            Layout.fillWidth: true
            visible: !self.context.mainnet && self.hasVisibleAmpAccounts && self.amp2Accounts.length === 0 && self.canCreateAmp2Account
            busy: self.creatingType === 'amp2'
            enabled: !self.creatingAccount
            onCreateClicked: self.createAmpAccount('amp2')
        }

        // AMP Legacy Section
        Repeater {
            model: self.context.mainnet ? [] : self.amp0Accounts
            delegate: AmpAccountCard {
                required property Account modelData
                Layout.fillWidth: true
                legacy: true
                title: UtilJS.accountName(modelData)
                subtitle: 'ID: ' + UtilJS.ampId(modelData)
                copyText: UtilJS.ampId(modelData)
            }
        }

        AmpMissingAccountCard {
            Layout.fillWidth: true
            visible: !self.context.mainnet && self.hasVisibleAmpAccounts && self.amp0Accounts.length === 0 && self.canCreateAmp0Account
            legacy: true
            busy: self.creatingType === '2of2_no_recovery'
            enabled: !self.creatingAccount
            onCreateClicked: self.createAmpAccount('2of2_no_recovery')
        }

        FixedErrorBadge {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            id: error_badge
            pointer: false
        }
    }

    component AmpCreateLinkButton: AbstractButton {
        property bool busy: false

        id: create_button
        focusPolicy: Qt.StrongFocus
        background: Item {
            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                border.color: '#00BCFF'
                border.width: 2
                color: 'transparent'
                visible: create_button.visualFocus
            }
        }
        contentItem: RowLayout {
            spacing: 4

            BusyIndicator {
                Layout.preferredHeight: 24
                Layout.preferredWidth: 24
                running: create_button.busy
                visible: create_button.busy
            }

            Label {
                color: Qt.lighter('#00BCFF', create_button.enabled && create_button.hovered ? 1.2 : 1)
                font.pixelSize: 14
                font.weight: 500
                lineHeight: 20
                lineHeightMode: Text.FixedHeight
                text: create_button.text
            }
        }
    }

    component AmpAccountCard: AbstractButton {
        property bool legacy: false
        property string title
        property string subtitle
        property string copyText

        id: account_card
        enabled: account_card.copyText !== ''
        horizontalPadding: 16
        verticalPadding: 12
        background: Rectangle {
            radius: 5
            color: Qt.lighter('#262626', account_card.hovered ? 1.2 : 1)
        }
        contentItem: RowLayout {
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                spacing: 2

                Item {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    implicitHeight: 20

                    Label {
                        id: account_title_label
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, Math.max(0, parent.width - (legacy_label.visible ? legacy_label.implicitWidth + legacy_label.anchors.leftMargin : 0)))
                        color: '#FFFFFF'
                        elide: Label.ElideRight
                        font.pixelSize: 13
                        font.weight: 600
                        lineHeightMode: Text.FixedHeight
                        text: account_card.title
                    }

                    Label {
                        id: legacy_label
                        anchors.left: account_title_label.right
                        anchors.leftMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        color: '#A0A0A0'
                        font.pixelSize: 13
                        font.weight: 600
                        lineHeightMode: Text.FixedHeight
                        text: '(' + qsTrId('id_legacy') + ')'
                        visible: account_card.legacy
                    }
                }

                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    color: '#A0A0A0'
                    elide: Label.ElideMiddle
                    font.pixelSize: 11
                    font.weight: 400
                    lineHeightMode: Text.FixedHeight
                    text: account_card.subtitle
                }
            }

            Image {
                Layout.preferredHeight: 24
                Layout.preferredWidth: 24
                source: copy_timer.running ? 'qrc:/svg2/check.svg' : 'qrc:/svg2/copy.svg'
            }
        }

        onClicked: {
            Clipboard.copy(account_card.copyText)
            copy_timer.restart()
        }

        Timer {
            id: copy_timer
            interval: 1000
            repeat: false
        }
    }

    component AmpMissingAccountCard: Pane {
        signal createClicked()
        property bool busy: false
        property bool legacy: false

        id: missing_card
        enabled: !self.creatingAccount
        padding: 16
        implicitHeight: 58
        background: Rectangle {
            radius: 5
            color: '#262626'
        }
        contentItem: RowLayout {
            spacing: 12

            RowLayout {
                id: missing_title_row
                Layout.fillWidth: true
                spacing: 2

                Label {
                    color: '#FFFFFF'
                    elide: Label.ElideRight
                    font.pixelSize: 13
                    font.weight: 600
                    lineHeightMode: Text.FixedHeight
                    text: 'AMP Liquid'
                }

                Label {
                    Layout.fillWidth: true
                    color: '#A0A0A0'
                    font.pixelSize: 13
                    font.weight: 600
                    lineHeightMode: Text.FixedHeight
                    text: '(' + qsTrId('id_legacy') + ')'
                    visible: missing_card.legacy
                }
            }

            AmpCreateLinkButton {
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                busy: missing_card.busy
                enabled: missing_card.enabled
                text: missing_card.busy ? 'Creating...' : qsTrId('id_create')
                onClicked: missing_card.createClicked()
            }
        }
    }
}
