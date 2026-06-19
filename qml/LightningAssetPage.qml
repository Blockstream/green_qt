import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    required property Context context
    required property Asset asset

    id: self

    LightningEnableController {
        id: controller
        context: self.context
    }

    title: self.asset.name
    rightItem: RowLayout {
        spacing: 12
        CircleButton {
            visible: env !== 'Production'
            icon.source: 'qrc:/svg/3-h-dots.svg'
            onClicked: self.pushPage(settings_view)
        }
        CloseButton {
            onClicked: self.closeClicked()
        }
    }
    bottomPadding: 0
    footer: null
    contentItem: TListView {
        id: list_view
        spacing: 8
        header: ColumnLayout {
            onHeightChanged: list_view.contentY = -(list_view.headerItem?.height ?? 0)
            width: list_view.width
            spacing: 0
            AssetIcon {
                Layout.alignment: Qt.AlignCenter
                asset: self.asset
                size: 48
            }
            Convert {
                id: convert
                context: self.context
                asset: self.asset
                input: ({ satoshi: self.context.lightningNodeInfo?.channel_balance ?? 0 })
                unit: UtilJS.unit(self.context)
            }
            Label {
                Layout.topMargin: 12
                Layout.alignment: Qt.AlignCenter
                color: '#FAFAFA'
                font.pixelSize: 24
                font.weight: 500
                text: UtilJS.incognito(Settings.incognito, convert.output.label)
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                color: '#A0A0A0'
                font.pixelSize: 14
                font.weight: 400
                text: UtilJS.incognito(Settings.incognito, convert.fiat.label)
                visible: convert.fiat.available
            }
            RowLayout {
                Layout.bottomMargin: 12
                Layout.topMargin: 12
                spacing: 8
                ActionButton {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    // TODO: enable when send flow is implemented
                    enabled: false
                    icon.source: 'qrc:/svg/send-white.svg'
                    text: qsTrId('id_send')
                }
                ActionButton {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    icon.source: 'qrc:/svg/receive-white.svg'
                    text: qsTrId('id_receive')
                    onClicked: self.StackView.view.push(lightning_receive_page)
                }
            }
            FieldTitle {
                Layout.bottomMargin: 12
                text: qsTrId('id_transactions')
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                color: '#929292'
                font.pixelSize: 14
                text: `You don't have any transactions yet.`
                visible: list_view.count === 0
                wrapMode: Label.Wrap
            }
        }
        model: TransactionModel {
            id: model
            context: self.context
            Component.onCompleted: model.updateFilterAssets(self.asset, true)
        }
        delegate: HomePage.TransactionDelegate2 {
            id: delegate
            onClicked: {
                self.pushPage(lightning_transaction_page, { transaction: delegate.transaction })
            }
        }
        footer: Item {
            implicitHeight: 0
        }
    }

    component ActionButton: PushButton {
        id: button
        fillColor: '#181818'
        borderColor: '#262626'
        textColor: '#FAFAFA'
        leftPadding: 20
        rightPadding: 20
        topPadding: 20
        bottomPadding: 20
        contentItem: ColumnLayout {
            spacing: 10
            Image {
                Layout.alignment: Qt.AlignCenter
                source: button.icon.source
                opacity: button.enabled ? 1 : 0.5
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                font.pixelSize: 14
                font.weight: 400
                color: '#FAFAFA'
                opacity: button.enabled ? 1 : 0.5
                text: button.text
            }
        }
    }

    component SettingsRow: Rectangle {
        required property string label
        required property string value
        property string copyText: row.value
        id: row
        Layout.fillWidth: true
        implicitHeight: 56
        color: '#181818'
        radius: 4
        border.width: 1
        border.color: '#262626'
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 12
            Label {
                Layout.alignment: Qt.AlignVCenter
                color: '#FAFAFA'
                font.pixelSize: 14
                font.weight: 500
                text: row.label
            }
            Label {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                color: '#A0A0A0'
                elide: Label.ElideMiddle
                font.pixelSize: 14
                font.weight: 400
                horizontalAlignment: Text.AlignRight
                text: row.value
            }
            AbstractButton {
                id: copy_button
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 24
                implicitHeight: 24
                opacity: copy_button.hovered ? 1 : 0.6
                background: Item {
                }
                contentItem: Image {
                    source: copy_timer.running ? 'qrc:/svg2/check.svg' : 'qrc:/svg2/copy.svg'
                }
                onClicked: {
                    Clipboard.copy(row.copyText)
                    copy_timer.restart()
                }
                Timer {
                    id: copy_timer
                    repeat: false
                    interval: 1000
                }
            }
        }
    }

    component SettingsAmountRow: SettingsRow {
        required property var satoshi
        id: amount_row
        value: convert.output.label
        copyText: convert.output.amount
        Convert {
            id: convert
            context: self.context
            asset: self.asset
            input: ({ satoshi: amount_row.satoshi })
            unit: UtilJS.unit(self.context)
        }
    }

    component SettingsButton: PrimaryButton {
        id: node_info_button
        Layout.fillWidth: true
        fillColor: node_info_button.hovered ? '#062F4A' : 'transparent'
        textColor: '#00BCFF'
    }

    Component {
        id: lightning_transaction_page
        LightningTransactionPage {
            context: self.context
            onCloseClicked: self.closeClicked()
        }
    }

    Component {
        id: lightning_receive_page
        LightningReceivePage {
            context: self.context
            onCloseClicked: self.closeClicked()
        }
    }

    Component {
        id: settings_view
        StackViewPage {
            id: settings_page
            readonly property var nodeInfo: self.context.lightningNodeInfo ?? {}
            title: 'Account Settings'
            leftItem: BackButton {
                onClicked: settings_page.popPage()
            }
            rightItem: CloseButton {
                onClicked: self.closeClicked()
            }
            contentItem: VFlickable {
                alignment: Qt.AlignTop
                spacing: 8
                FieldTitle {
                    text: qsTrId('id_details')
                }
                SettingsRow {
                    label: 'Node ID'
                    value: settings_page.nodeInfo.id ?? '-'
                    copyText: settings_page.nodeInfo.id ?? ''
                }
                SettingsAmountRow {
                    label: qsTrId('id_account_balance')
                    satoshi: settings_page.nodeInfo.channel_balance ?? 0
                }
                SettingsAmountRow {
                    label: 'Onchain Balance'
                    satoshi: settings_page.nodeInfo.onchain_balance ?? 0
                }
                SettingsAmountRow {
                    label: 'Inbound Liquidity'
                    satoshi: settings_page.nodeInfo.inbound_liquidity ?? 0
                }
                SettingsAmountRow {
                    label: qsTrId('id_max_payable_amount')
                    satoshi: settings_page.nodeInfo.max_payable ?? 0
                }
                SettingsAmountRow {
                    label: qsTrId('id_max_receivable_amount')
                    satoshi: settings_page.nodeInfo.max_receivable ?? 0
                }
                VSpacer {
                }
                SettingsButton {
                    text: qsTrId('id_show_recovery_phrase')
                    onClicked: self.pushPage(lightning_mnemonic_page)
                }
                SettingsButton {
                    text: 'Disable Lightning'
                    onClicked: {
                        controller.disable()
                        self.closeClicked()
                    }
                }
            }
        }
    }

    Component {
        id: lightning_mnemonic_page
        StackViewPage {
            id: recovery_page

            title: qsTrId('id_recovery_phrase')
            leftItem: BackButton {
                onClicked: recovery_page.popPage()
            }
            rightItem: CloseButton {
                onClicked: self.closeClicked()
            }
            contentItem: VFlickable {
                alignment: Qt.AlignTop
                spacing: 20
                VSpacer {
                }
                Pane {
                    Layout.alignment: Qt.AlignCenter
                    background: null
                    contentItem: MnemonicView {
                        columns: 2
                        mnemonic: self.context.lightningMnemonic
                    }
                }
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    color: '#A0A0A0'
                    font.pixelSize: 14
                    font.weight: 400
                    text: 'This is a BIP-85 recovery phrase for your Lightning node. It is different from your wallet recovery phrase.'
                    horizontalAlignment: Label.AlignHCenter
                    wrapMode: Label.Wrap
                }
                VSpacer {
                }
                RegularButton {
                    Layout.fillWidth: true
                    enabled: self.context.lightningMnemonic.length > 0
                    text: qsTrId('id_show_qr_code')
                    onClicked: recovery_page.pushPage(qrcode_page)
                }
            }

            Component {
                id: qrcode_page
                StackViewPage {
                    id: qr_page
                    title: recovery_page.title
                    leftItem: BackButton {
                        onClicked: qr_page.popPage()
                    }
                    rightItem: CloseButton {
                        onClicked: self.closeClicked()
                    }
                    contentItem: VFlickable {
                        alignment: Qt.AlignTop
                        QRCode {
                            Layout.alignment: Qt.AlignHCenter
                            text: self.context.lightningMnemonic.join(' ')
                            implicitHeight: 300
                            implicitWidth: 300
                            radius: 4
                        }
                    }
                }
            }
        }
    }
}
