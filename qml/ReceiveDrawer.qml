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
        session: self.account.session
        account: self.account
        asset: self.asset
        convert.unit: self.account.session.unit
    }

    TaskPageFactory {
        title: receive_view.title
        monitor: controller.monitor
        target: stack_view
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
                    enabled: !controller.generating
                    text: qsTrId('id_verify_on_device')
                    visible: controller.context.wallet.login.device?.type === 'jade'
                    onClicked: {
                        stack_view.push(jade_verify_page, { context: self.context, address: controller.address })
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
                    AbstractButton {
                        Layout.fillWidth: true
                        padding: 20
                        visible: controller.account.network.liquid && controller.context.wallet.login.device?.type === 'nanos'
                        background: Rectangle {
                            color: '#e5e7e9'
                            radius: 5
                        }
                        contentItem: RowLayout {
                            spacing: 10
                            Image {
                                Layout.alignment: Qt.AlignCenter
                                source: 'qrc:/svg/warning_black.svg'
                            }
                            Label {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                color: 'black'
                                font.pixelSize: 14
                                font.weight: 400
                                text: qsTrId('id_ledger_supports_a_limited_set')
                                wrapMode: Label.Wrap
                            }
                        }
                        onClicked: Qt.openUrlExternally('https://docs.blockstream.com/green/hww/hww-index.html#ledger-supported-assets')
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
                            spacing: 20
                            RowLayout {
                                Item {
                                    Layout.minimumWidth: rhs.width
                                }
                                QRCode {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.fillWidth: true
                                    Layout.margins: 20
                                    id: qrcode
                                    text: controller.uri
                                    implicitHeight: 196
                                    implicitWidth: 196
                                    radius: 8
                                    corners: true
                                    AssetIcon {
                                        anchors.centerIn: parent
                                        asset: controller.asset
                                        size: 64
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
                                }
                            }
                            AddressVerifiedBadge {
                                address: controller.address
                            }
                            AddressLabel {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                address: controller.address
                            }
                            RowLayout {
                                spacing: 10
                                ToolButton {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 0
                                    icon.source: 'qrc:/svg2/zoom.svg'
                                    text: qsTrId('id_increase_qr_size')
                                    onClicked: stack_view.push(qrcode_page)
                                }
                                CopyAddressButton {
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 0
                                    content: controller.uri
                                    text: qsTrId('id_copy_address')
                                }
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
    component ToolButton: AbstractButton {
        id: self
        padding: 10
        background: Item {
            Rectangle {
                anchors.fill: parent
                border.width: 2
                border.color: '#00B45A'
                color: 'transparent'
                radius: 8
                visible: self.visualFocus
            }
            Rectangle {
                anchors.fill: parent
                anchors.margins: self.visualFocus ? 4 : 0
                color: Qt.alpha(Qt.darker('#13161D'), 0.6)
                radius: self.visualFocus ? 4 : 8
            }
        }
        contentItem: RowLayout {
            spacing: 10
            Item {
                Layout.minimumHeight: 22
                Layout.minimumWidth: 22
                Image {
                    anchors.centerIn: parent
                    source: self.icon.source
                }
            }
            Label {
                font.pixelSize: 12
                font.weight: 600
                text: self.text
            }
        }
    }

    Component {
        id: address_details_page
        AddressDetailsPage {
        }
    }
}
