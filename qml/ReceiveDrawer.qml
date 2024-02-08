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
        asset: self.asset
        convert.unit: self.account.session.unit
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
            footer: RowLayout {
                spacing: 20
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
                PrimaryButton {
                    Layout.fillWidth: true
                    enabled: (controller.context.device?.connected ?? false) && !controller.generating && controller.addressVerification !== ReceiveAddressController.VerificationPending
                    text: qsTrId('id_verify_on_device')
                    visible: {
                        if (controller.context.device instanceof JadeDevice) {
                            switch (controller.context.device.state) {
                            case JadeDevice.StateReady:
                            case JadeDevice.StateTemporary:
                            case JadeDevice.StateLocked:
                                return true
                            }
                        }
                        return false
                    }
                    onClicked: {
                        stack_view.push(jade_verify_page, { device: controller.context.device, controller })
                        Analytics.recordEvent('verify_address', AnalyticsJS.segmentationSubAccount(Settings, controller.account))
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
                            RowLayout {
                                Item {
                                    Layout.minimumWidth: rhs.width
                                }
                                QRCode {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.fillWidth: true
                                    id: qrcode
                                    text: controller.uri
                                    implicitHeight: 150
                                    implicitWidth: 150
                                    radius: 8
                                    AssetIcon {
                                        anchors.centerIn: parent
                                        asset: controller.asset
                                        size: 32
                                        border: 4
                                        visible: !!controller.asset
                                    }
                                }
                                ColumnLayout {
                                    Layout.alignment: Qt.AlignTop
                                    id: rhs
                                    spacing: 10
                                    CircleButton {
                                        Layout.alignment: Qt.AlignTop
                                        icon.source: 'qrc:/svg2/refresh.svg'
                                        onClicked: controller.generate()
                                    }
                                    CircleButton {
                                        Layout.alignment: Qt.AlignTop
                                        icon.source: 'qrc:/svg2/zoom.svg'
                                        onClicked: stack_view.push(qrcode_page)
                                    }
                                }
                            }
                            AddressVerifiedBadge {
                                address: controller.address
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
                        text: qsTrId('id_request_amount')
                        visible: amount_field.visible
                    }
                    AmountField {
                        Layout.fillWidth: true
                        id: amount_field
                        convert: controller.convert
                        unit: self.account.session.unit
                        visible: false
                    }
                }
            }
        }
    }

    Component {
        id: jade_verify_page
        JadeVerifyAddressPage {
        }
    }

    Component {
        id: qrcode_page
        StackViewPage {
            title: qsTrId('id_receive')
            contentItem: ColumnLayout {
                spacing: 20
                id: layout
                VSpacer {
                }
                QRCode {
                    Layout.alignment: Qt.AlignHCenter
                    id: qrcode
                    border: 16
                    layer.enabled: true
                    text: controller.uri
                    Layout.fillWidth: true
                    Layout.minimumHeight: layout.width
                    radius: 4
                    opacity: slider.value
                }
                RowLayout {
                    Layout.alignment: Qt.AlignCenter
                    Image {
                        source: 'qrc:/svg2/sun-dim.svg'
                    }
                    Slider {
                        Layout.maximumWidth: 120
                        id: slider
                        from: 0.4
                        to: 1
                        value: 1
                    }
                    Image {
                        source: 'qrc:/svg2/sun.svg'
                    }
                }
                VSpacer {
                }
            }
        }
    }

    Component {
        id: account_asset_selector
        ReceiveAccountAssetSelector {
            id: selector
            context: controller.context
            account: controller.account
            asset: controller.asset
            onSelected: (account, asset) => {
                stack_view.pop(receive_view)
                controller.account = account
                controller.asset = asset
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
                    model: AddressListModel {
                        filter: search_field.text
                        account: page.account
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
