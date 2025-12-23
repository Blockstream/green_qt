import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

StackViewPage {
    required property Account account
    required property Asset asset
    required property Context context
    property bool readonly: false

    ReceiveAddressController {
        id: controller
        context: self.context
        session: controller.account.session
        account: self.account
        asset: self.asset
        convert.unit: controller.account.session.unit
    }

    TaskPageFactory {
        title: self.title
        monitor: controller.monitor
        target: self.StackView.view
    }

    id: self
    title: qsTrId('id_receive')
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    footerItem: ColumnLayout {
        spacing: -1
        TransactionView.ActionButton {
            icon.source: 'qrc:/svg2/gauge-green.svg'
            enabled: !controller.generating && (controller.context.device?.connected ?? false)
            text: qsTrId('id_verify_on_device')
            visible: controller.context.wallet.login.device?.type === 'jade'
            onClicked: {
                self.StackView.view.push(jade_verify_page, { context: self.context, address: controller.address })
                Analytics.recordEvent('verify_address', AnalyticsJS.segmentationSubAccount(Settings, controller.account))
            }
        }
        TransactionView.ActionButton {
            icon.source: 'qrc:/svg2/arrow_square_down.svg'
            text: qsTrId('id_request_amount')
            visible: !amount_field.visible
            onClicked: {
                amount_field.visible = true
                amount_field.forceActiveFocus()
            }
        }
        TransactionView.ActionButton {
            icon.source: 'qrc:/svg2/list_bullets.svg'
            text: qsTrId('id_list_of_addresses')
            visible: !self.note
            onClicked: {
                self.StackView.view.push(addresses_page, { account: controller.account })
            }
        }
    }
    contentItem: VFlickable {
        alignment: Qt.AlignTop
        spacing: 5
        FieldTitle {
            Layout.topMargin: 0
            text: qsTrId('id_account__asset')
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
            readonly: self.readonly
            onClicked: self.StackView.view.push(account_asset_selector)
        }
        FieldTitle {
            text: qsTrId('id_account_address')
        }
        Pane {
            Layout.fillWidth: true
            padding: 20
            background: Rectangle {
                radius: 5
                color: '#181818'
                border.color: '#262626'
                border.width: 1
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
                        Layout.margins: 10
                        id: qrcode
                        text: controller.uri
                        implicitHeight: 192
                        implicitWidth: 192
                        radius: 8
                        border: 8
                        corners: true
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
                        onClicked: self.StackView.view.push(qrcode_page)
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
            text: qsTrId('id_request_amount')
            visible: amount_field.visible
        }
        AmountField {
            Layout.fillWidth: true
            id: amount_field
            convert: controller.convert
            session: controller.account.session
            visible: false
        }
        VSpacer {
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
            onSelected: (account, asset) => {
                controller.account = account
                controller.asset = asset
                self.StackView.view.pop(self)
            }
        }
    }

    Component {
        id: addresses_page
        StackViewPage {
            required property Account account
            Component.onCompleted: address_model.updateFilterAccounts(page.account, true)
            id: page
            title: qsTrId('id_addresses')
            rightItem: CloseButton {
                onClicked: self.closeClicked()
            }
            contentItem: ColumnLayout {
                spacing: 5
                SearchField {
                    Layout.fillWidth: true
                    id: search_field
                }
                TListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    id: list_view
                    spacing: 5
                    model: AddressModel {
                        id: address_model
                        context: self.context
                        filterText: search_field.text
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
        leftPadding: 15
        rightPadding: 15
        bottomPadding: 15
        topPadding: 15
        background: Rectangle {
            color: '#181818'
            radius: 5
        }
        contentItem: RowLayout {
            spacing: 10
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.alignment: Qt.AlignCenter
                font.pixelSize: 12
                font.weight: 500
                text: delegate.address.address
                wrapMode: Label.Wrap
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                font.pixelSize: 12
                font.weight: 500
                text: delegate.address.data?.tx_count ?? '0'
            }
            RightArrowIndicator {
                active: delegate.hovered
            }
        }
        onClicked: self.StackView.view.push(address_details_page, { context: self.context, address: delegate.address })
    }
    component ToolButton: AbstractButton {
        id: self
        padding: 10
        background: Item {
            Rectangle {
                anchors.fill: parent
                border.width: 2
                border.color: '#00BCFF'
                color: 'transparent'
                radius: 8
                visible: self.visualFocus
            }
            Rectangle {
                anchors.fill: parent
                anchors.margins: self.visualFocus ? 4 : 0
                color: Qt.alpha(Qt.darker('#181818'), 0.6)
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
            onCloseClicked: self.closeClicked()
        }
    }
}
