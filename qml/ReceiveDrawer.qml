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
    width: 500
    contentItem: GStackView {
        id: stack_view
        initialItem: Page {
            background: null
            header: Pane {
                background: null
                padding: 0
                bottomPadding: 20
                contentItem: RowLayout {
                    DrawerTitle {
                        text: qsTrId('id_receive')
                    }
                    HSpacer {
                    }
                    CloseButton {
                        onClicked: self.close()
                    }
                }
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
                            font.family: 'SF Compact Display'
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
            onCanceled: stack_view.pop()
            onSelected: (account, asset) => {
                stack_view.pop()
                controller.account = account
                controller.asset = asset
            }
            onCreate: (asset) => {
                stack_view.push(create_account_page, { asset })
            }
        }
    }

    Component {
        id: create_account_page
        CreateAccountPage {
            context: self.context
            onCanceled: stack_view.pop()
        }
    }
}
