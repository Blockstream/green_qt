import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    signal closed()
    required property Context context
    required property TwoFactorExpiredNotification notification
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
            spacing: 0
            width: flickable.width
            MultiImage {
                Layout.alignment: Qt.AlignCenter
                foreground: 'qrc:/png/2fa_expired.png'
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
                Layout.bottomMargin: 8
                Layout.fillWidth: true
                Layout.maximumWidth: 350
                Layout.preferredWidth: 0
                color: '#fff'
                font.pixelSize: 14
                font.weight: 400
                text: `Some coins in your wallet haven't moved for a long time, so 2FA expired to keep you in control. To reactivate 2FA:`
                wrapMode: Label.Wrap
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.bottomMargin: 8
                Layout.fillWidth: true
                Layout.maximumWidth: 350
                Layout.preferredWidth: 0
                color: '#fff'
                font.pixelSize: 14
                font.weight: 400
                text: '\u2022 Send normally and refresh the 2FA on change coins (optimizes fees)'
                wrapMode: Label.Wrap
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.bottomMargin: 16
                Layout.fillWidth: true
                Layout.maximumWidth: 350
                Layout.preferredWidth: 0
                color: '#fff'
                font.pixelSize: 14
                font.weight: 400
                text: '\u2022 Redeposit all your expired 2FA coins'
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
                        self.StackView.view.push(redeposit_page, {
                            account: delegate.account,
                        })
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
            color: Qt.lighter('#222226', button.enabled && button.hovered ? 1.1 : 1)
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
            onClosed: self.closed()
        }
    }
}
