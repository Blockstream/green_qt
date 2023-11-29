import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

WalletDrawer {
    required property Account account
    property Asset asset

    ReceiveAddressController {
        id: controller
        context: self.context
        account: self.account
        amount: '0'
    }

    id: self
    preferredContentWidth: stack_view.currentItem.implicitWidth
    contentItem: GStackView {
        id: stack_view
        initialItem: StackViewPage {
            id: receive_view
            title: qsTrId('id_receive')
            rightItem: CloseButton {
                onClicked: self.reject()
            }
            contentItem: ColumnLayout {
                spacing: 5
                FieldTitle {
                    text: 'Asset & Account'
                }
                AccountAssetField {
                    Layout.fillWidth: true
                    account: controller.account
                    asset: controller.asset
                    onClicked: stack_view.push(account_asset_selector)
                }
                FieldTitle {
                    Layout.topMargin: 15
                    text: 'Account Address'
                }
                Pane {
                    Layout.fillWidth: true
                    padding: 20
                    background: Rectangle {
                        radius: 5
                        color: '#222226'
                    }
                    contentItem: ColumnLayout {
                        spacing: 10
                        RefreshButton {
                            Layout.alignment: Qt.AlignRight
                            onClicked: controller.generate()
                        }
                        QRCode {
                            Layout.alignment: Qt.AlignHCenter
                            id: qrcode
                            text: controller.uri
                            implicitHeight: 200
                            implicitWidth: 200
                            radius: 4
                        }
                        Label {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            font.pixelSize: 12
                            font.weight: 500
                            horizontalAlignment: Label.AlignHCenter
                            text: controller.uri
                            wrapMode: Label.WrapAnywhere
                        }
                        CopyAddressButton {
                            Layout.alignment: Qt.AlignCenter
                            address: controller.uri
                        }
                    }
                }

                VSpacer {
                }
                RowLayout {
                    spacing: 26
                    RegularButton {
                        Layout.horizontalStretchFactor: 1
                        Layout.fillWidth: true
                        text: 'More Options'
                    }
                    PrimaryButton {
                        Layout.horizontalStretchFactor: 1
                        Layout.fillWidth: true
                        text: 'Share'
                        onClicked: self.accept()
                    }
                }
            }
        }
    }

    Component {
        id: account_asset_selector
        AccountAssetSelector {
            context: controller.context
            account: controller.account
            asset: controller.asset
            showCreateAccount: true
            onSelected: (account, asset) => {
                stack_view.pop(receive_view)
                controller.account = account
                controller.asset = asset
            }
        }
    }
}
