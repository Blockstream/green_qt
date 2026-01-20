import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    required property Context context
    required property TwoFactorExpiredNotification notification
    objectName: "TwoFactorExpiredSelectAccountPage"
    id: self
    contentItem: Flickable {
        ScrollIndicator.vertical: ScrollIndicator {
        }
        id: flickable
        clip: true
        contentWidth: flickable.width
        contentHeight: layout.height
        ColumnLayout {
            id: layout
            spacing: 16
            width: flickable.width
            MultiImage {
                Layout.alignment: Qt.AlignCenter
                foreground: 'qrc:/svg3/2fa_expired.svg'
                width: 352
                height: 240
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.maximumWidth: 350
                color: '#fff'
                font.pixelSize: 26
                font.weight: 600
                text: 'Re-enable 2FA'
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                Layout.maximumWidth: 300
                font.pixelSize: 12
                font.weight: 400
                horizontalAlignment: Label.AlignJustify
                opacity: 0.6
                text: `2FA Protected accounts are 2-of-2 wallets needing the user’s key and Blockstream’s 2FA signature. After a ~1-year timelock, they become 1-of-1, disabling 2FA, to ultimately keep you in control. Redeposit your coins to reactivate 2FA protection.`
                wrapMode: Label.Wrap
            }
            Repeater {
                model: self.notification.accounts
                delegate: AccountButton {
                    required property var modelData
                    Layout.topMargin: 8
                    Layout.fillWidth: true
                    id: delegate
                    account: delegate.modelData
                    onClicked: {
                        const account = delegate.account
                        const page = account.network.liquid ? redeposit_liquid_page : redeposit_page
                        self.StackView.view.push(page, { account })
                    }
                }
            }
        }
    }
    footer: RowLayout {
        LinkButton {
            Layout.alignment: Qt.AlignCenter
            text: qsTrId('id_learn_more')
            onClicked: Qt.openUrlExternally('https://help.blockstream.com/hc/en-us/articles/900001391763-How-does-Blockstream-Green-s-2FA-multisig-protection-work#h_01HRYKB9YRHWX02REXYY34VPV9')
        }
    }

    component AccountButton: AbstractButton {
        required property Account account
        id: button
        leftPadding: 20
        rightPadding: 20
        topPadding: 20
        bottomPadding: 20
        background: Rectangle {
            color: Qt.lighter('#262626', button.enabled && button.hovered ? 1.1 : 1)
            radius: 5
        }
        contentItem: RowLayout {
            ColumnLayout {
                RowLayout {
                    Image {
                        fillMode: Image.PreserveAspectFit
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        source: button.account.network.electrum ? 'qrc:/svg2/singlesig.svg' : 'qrc:/svg2/multisig.svg'
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        color: '#fff'
                        font.pixelSize: 10
                        font.weight: 400
                        opacity: 0.6
                        text: UtilJS.networkLabel(button.account.network) + ' / ' + UtilJS.accountLabel(button.account)
                        wrapMode: Label.Wrap
                    }
                }
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    color: '#fff'
                    font.pixelSize: 16
                    font.weight: 600
                    text: UtilJS.accountName(button.account)
                    wrapMode: Label.Wrap
                }
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    color: '#fff'
                    font.pixelSize: 12
                    font.weight: 400
                    opacity: 0.6
                    text: 'Redeposit Expired 2FA Coins'
                    wrapMode: Label.Wrap
                }
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                visible: self.enabled
                source: 'qrc:/svg2/next_arrow.svg'
            }
        }
    }

    Component {
        id: redeposit_page
        RedepositPage {
            context: self.context
            onCloseClicked: self.closeClicked()
        }
    }

    Component {
        id: redeposit_liquid_page
        RedepositLiquidPage {
            context: self.context
            onCloseClicked: self.closeClicked()
        }
    }
}
