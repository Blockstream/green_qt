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
        account: self.account
        amount: '10'
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
                    Label {
                        font.family: 'SF Compact Display'
                        font.pixelSize: 20
                        font.weight: 790
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
                Label {
                    font.family: 'SF Compact Display'
                    font.pixelSize: 14
                    font.weight: 600
                    opacity: 0.4
                    text: 'Asset & Account'
                }
                AccountAssetField {
                    Layout.fillWidth: true
                    account: controller.account
                    asset: controller.asset
                    onClicked: stack_view.push(account_asset_selector)
                }
                Label {
                    Layout.topMargin: 15
                    font.family: 'SF Compact Display'
                    font.pixelSize: 14
                    font.weight: 600
                    opacity: 0.4
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
                        Image {
                            Layout.alignment: Qt.AlignRight
                            source: 'qrc:/svg2/refresh.svg'
                            TapHandler {
                                onTapped: controller.generate()
                            }
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
            account: controller.account
            asset: controller.asset
            onCanceled: stack_view.pop()
            onSelected: (account, asset) => {
                stack_view.pop()
                controller.account = account
                controller.asset = asset
            }
        }
    }
}
