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

    onClosed: self.destroy()

    ReceiveAddressController {
        id: controller
        context: self.context
        account: self.account
        amount: '0'
    }

    id: self
    preferredContentWidth: stack_view.currentItem.implicitWidth
    minimumContentWidth: 400
    contentItem: GStackView {
        id: stack_view
        initialItem: StackViewPage {
            id: receive_view
            title: qsTrId('id_receive')
            rightItem: CloseButton {
                onClicked: self.close()
            }
            footer: ColumnLayout {
                PrimaryButton {
                    Layout.fillWidth: true
                    enabled: !controller.generating && controller.addressVerification !== ReceiveAddressController.VerificationPending
                    text: qsTrId('id_verify_on_device')
                    visible: controller.context.device instanceof JadeDevice
                    onClicked: {
                        stack_view.push(jade_verify_page)
                        Analytics.recordEvent('verify_address', AnalyticsJS.segmentationSubAccount(controller.account))
                    }
                }
                RegularButton {
                    id: more_options_button
                    Layout.fillWidth: true
                    text: qsTrId('id_more_options')
                    onClicked: if (!more_options_menu.visible) more_options_menu.open()
                    MoreOptionsMenu {
                        id: more_options_menu
                        x: (more_options_button.width - more_options_menu.width) / 2
                        y: -more_options_menu.height - 6
                        pointerX: 0.5
                        pointerY: 1
                    }
                }
            }
            contentItem: Flickable {
                ScrollIndicator.vertical: ScrollIndicator {
                }
                id: flickable
                clip: true
                contentWidth: flickable.width
                contentHeight: layout.height
                ColumnLayout {
                    id: layout
                    spacing: 5
                    width: flickable.width
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
                                content: controller.uri
                                text: qsTrId('id_copy_address')
                            }
                        }
                    }
                    FieldTitle {
                        Layout.topMargin: 15
                        text: 'Account Address'
                        visible: amount_field.visible
                    }
                    AmountField {
                        Layout.fillWidth: true
                        id: amount_field
                        text: controller.amount
                        visible: false
                        onTextEdited: controller.amount = amount_field.text
                    }
                }
            }
        }
    }

    Component {
        id: jade_verify_page
        StackViewPage {
            StackView.onActivated: controller.verify()
            Timer {
                running: controller.addressVerification === ReceiveAddressController.VerificationAccepted
                interval: 1000
                onTriggered: stack_view.pop()
            }
            title: qsTrId('id_verify_on_device')
            footer: BusyIndicator {
                Layout.alignment: Qt.AlignCenter
                running: controller.addressVerification !== ReceiveAddressController.VerificationPending
            }
            contentItem: ColumnLayout {
                VSpacer {
                }
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    font.pixelSize: 14
                    font.weight: 500
                    horizontalAlignment: Label.AlignHCenter
                    text: controller.address
                    wrapMode: Label.Wrap
                }
                Image {
                    Layout.alignment: Qt.AlignCenter
                    source: 'qrc:/png/connect_jade_2.png'
                }
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    font.pixelSize: 12
                    font.weight: 500
                    horizontalAlignment: Label.AlignHCenter
                    text: qsTrId('id_please_verify_that_the_address')
                    wrapMode: Label.WordWrap
                }
                VSpacer {
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

    Component {
        id: request_amount_dialog
        Popup {
            modal: true
            contentItem: ColumnLayout {
                AmountField {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 350
                    id: amount_field
                    text: controller.amount
                    onTextEdited: controller.amount = amount_field.text
                }
            }
        }
    }

    component MoreOptionsMenu: GMenu {
        id: menu
        GMenu.Item {
            enabled: !amount_field.visible
            text: qsTrId('id_request_amount')
            icon.source: 'qrc:/svg2/arrow_square_down.svg'
            onClicked: {
                menu.close()
                amount_field.visible = true
                amount_field.forceActiveFocus()
                // request_amount_dialog.createObject(self.contentItem).open()
            }
        }
        GMenu.Item {
            text: 'List of Addresses'
            icon.source: 'qrc:/svg2/list_bullets.svg'
            onClicked: {
                menu.close()
                stack_view.push(addresses_page, { account: controller.account })
            }
        }
    }

    Component {
        id: addresses_page
        StackViewPage {
            required property Account account
            id: page
            title: qsTrId('id_addresses')
            contentItem: ColumnLayout {
                spacing: 20
                SearchField {
                    Layout.fillWidth: true
                    id: search_field
                }
                TListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    id: list_view
                    spacing: 5
                    model: AddressListModelFilter {
                        filter: search_field.text
                        model: AddressListModel {
                            account: page.account
                        }
                    }
                    delegate: AddressDelegate2 {
                        width: list_view.width
                    }
                }
            }
        }
    }

    component AddressDelegate2: ItemDelegate {
        required property Address address
        id: delegate
        text: JSON.stringify(delegate.address.data, null, '  ')
        leftPadding: 15
        rightPadding: 15
        bottomPadding: 15
        topPadding: 15
        background: Rectangle {
            color: '#34373E'
            radius: 4
        }
        contentItem: RowLayout {
            spacing: 10
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.alignment: Qt.AlignCenter
                font.pixelSize: 12
                font.weight: 500
                text: delegate.address.data.address
                wrapMode: Label.Wrap
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                font.pixelSize: 22
                font.weight: 400
                text: delegate.address.data.tx_count
            }
        }
        onClicked: stack_view.push(address_details_page, { context: self.context, address: delegate.address })
    }

    Component {
        id: address_details_page
        AddressDetailsPage {
        }
    }
}
