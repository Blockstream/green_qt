import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

WalletDrawer {
    property Asset asset
    property url url
    id: self
    closePolicy: AbstractDrawer.CloseOnEscape
    minimumContentWidth: 450
    contentItem: GStackView {
        id: stack_view
        initialItem: RecipientPage {
            onCloseClicked: self.close()
        }
    }
    AnalyticsView {
        name: 'Send'
        active: true
        segmentation: AnalyticsJS.segmentationSession(Settings, self.context)
    }
    onClosed: {
        if (self.url && stack_view.currentItem instanceof SendPage) {
            WalletManager.openUrl = self.url
        }
    }

    component RecipientPage: StackViewPage {
        property string address_input
        function next() {
            const network = controller.networks[0]
            if (!network) return

            if (network.liquid && !controller.bip21.assetid) {
                stack_view.push(asset_selector_page, {
                    address: controller.address,
                    amount: controller.amount,
                    input: page.address_input,
                    networks: controller.networks
                })
            } else {
                stack_view.push(account_selector_page, {
                    address: controller.address,
                    amount: controller.amount,
                    asset: controller.asset,
                    input: page.address_input,
                })
            }
        }

        id: page
        title: qsTrId('id_send')
        rightItem: CloseButton {
            onClicked: page.closeClicked()
        }
        footerItem: PrimaryButton {
            enabled: controller.networks.length > 0
            text: qsTrId('id_next')
            onClicked: page.next()
        }

        contentItem: VFlickable {
            alignment: Qt.AlignTop
            spacing: 5
            FieldTitle {
                Layout.topMargin: 0
                text: qsTrId('id_send_to')
            }
            GTextArea {
                property string previousText: ''
                Layout.fillWidth: true
                Layout.minimumHeight: 200
                id: address_field
                focus: true
                rightPadding: 15
                bottomPadding: 50
                error: {
                    if (address_field.text.trim().length === 0) return null
                    if (controller.errors.length === 0) return null
                    return controller.errors[0]
                }
                RowLayout {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottomMargin: 13
                    anchors.leftMargin: 15
                    anchors.rightMargin: 15
                    spacing: 10
                    CircleButton {
                        activeFocusOnTab: false
                        icon.source: 'qrc:/svg2/paste.svg'
                        onClicked: {
                            address_field.clear()
                            address_field.paste()
                        }
                    }
                    CircleButton {
                        activeFocusOnTab: false
                        enabled: scanner_popup.available && !scanner_popup.visible
                        icon.source: 'qrc:/svg2/qrcode.svg'
                        onClicked: scanner_popup.requestPermissionAndOpen()
                        ScannerPopup {
                            id: scanner_popup
                            onCodeScanned: (code) => {
                                page.address_input = 'scan'
                                address_field.text = code
                            }
                        }
                    }
                    HSpacer {
                    }
                    CircleButton {
                        enabled: address_field.text.length > 0
                        activeFocusOnTab: false
                        icon.source: 'qrc:/svg2/x-circle.svg'
                        onClicked: {
                            address_field.clear()
                        }
                    }
                }
                onTextChanged: {
                    page.address_input = address_field.text.length === 0 ? '' : Math.abs(address_field.previousText.length - address_field.text.length) > 1 ? 'paste' : 'type'
                    address_field.previousText = address_field.text
                }
            }
            RedepositPage.ErrorPane {
                Layout.topMargin: -20
                Layout.bottomMargin: 15
                error: address_field.error
            }
            AddressValidationController {
                id: controller
                context: self.context
                input: address_field.text.trim()
                onAssetChanged: asset_field.asset = controller.asset
                onUpdated: {
                    if (page.address_input === 'type') return

                    page.next()
                }
            }
            ColumnLayout {
                Layout.fillHeight: false
                Layout.topMargin: 10
                spacing: 5
                visible: controller.networks.length > 0
                FieldTitle {
                    text: qsTrId('id_asset')
                    visible: asset_field.visible
                }
                AssetField {
                    Layout.fillWidth: true
                    id: asset_field
                    editable: false
                    visible: !controller.networks[0]?.liquid || !!controller.bip21?.assetid
                }
                FieldTitle {
                    text: (controller.networks[0]?.displayName ?? '') + ' ' + qsTrId('id_address')
                }
                AddressLabel {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    address: controller.address
                    padding: 20
                    background: Rectangle {
                        color: '#181818'
                        radius: 5
                    }
                }
                FieldTitle {
                    text: qsTrId('id_amount')
                    visible: amount_field.visible
                }
                AmountField {
                    Layout.fillWidth: true
                    id: amount_field
                    readOnly: true
                    session: self.context.getOrCreateSession(controller.networks[0])
                    visible: Object.keys(controller.amount).length > 0
                    convert: Convert {
                        asset: controller.asset
                        context: self.context
                        input: controller.amount
                        unit: self.context.getOrCreateSession(controller.networks[0])?.unit ?? 'btc'
                    }
                }
            }
            VSpacer {
            }
        }
    }

    Component {
        id: asset_selector_page
        AssetSelectorPage {
            required property string address
            required property var amount
            required property string input
            id: page
            context: self.context
            onAssetClicked: (asset) => {
                stack_view.push(account_selector_page, {
                    address: page.address,
                    amount: page.amount,
                    asset,
                    input: page.input,
                })
            }
        }
    }

    Component {
        id: account_selector_page
        AccountSelectorPage {
            required property string address
            required property var amount
            required property string input
            id: page
            context: self.context
            message: ''
            onAccountClicked: (account) => {
                stack_view.push(send_details_page, {
                    account,
                    address: page.address,
                    amount: page.amount,
                    input: page.input,
                    asset: page.asset,
                })
            }
        }
    }

    // Component {
    //     id: account_asset_selector
    //     SendAccountAssetSelector {
    //         required property string address
    //         required property string input
    //         id: page
    //         context: self.context
    //         onSelected: (account, asset) => {
    //             stack_view.push(send_details_page, {
    //                 address: page.address,
    //                 input: page.input,
    //                 account,
    //                 asset,
    //             })
    //         }
    //     }
    // }

    Component {
        id: send_details_page
        SendDetailsPage {
            context: self.context
            onCloseClicked: self.close()
        }
    }
}
