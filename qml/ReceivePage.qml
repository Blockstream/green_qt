import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS

StackViewPage {
    required property Account account
    required property Asset asset
    required property Context context
    property bool readonly: false
    property bool invoice: false
    readonly property bool lightningEnabled: self.context.mainnet && !self.context.watchonly && !controller.context.wallet.login.device && self.account.network.liquid && self.asset.id === self.account.network.policyAsset
    readonly property string qrcode: controller.uri
    property bool lockAssetAndAccount: false
    property bool invoicePushed: false
    function openLightningInvoice() {
        if (!self.invoice || !invoice_controller.swap) return

        const sendAmount = Number(quote_controller.quote?.send_amount ?? 0)
        const receiveAmount = Number(quote_controller.quote?.receive_amount ?? 0)
        self.invoicePushed = true
        self.pushPage(lightning_invoice_page, {
            invoice: invoice_controller.swap?.data?.invoice ?? '',
            expiresAt: invoice_controller.swap?.data?.expiresAt ?? null,
            amountSats: sendAmount,
            totalFeesSats: sendAmount - receiveAmount,
        })
    }
    readonly property var error: {
        if (!self.invoice) return null
        if (amount_field.text.length === 0) return { code: 'invalid', visible: false }
        const amount = Number(controller.convert.result?.satoshi ?? 0)
        let value = Number(quote_controller.quote?.min ?? 100)
        if (amount < value) {
            return { code: 'id_amount_below_minimum_allowed', value, visible: true }
        }
        value = Number(quote_controller.quote?.max ?? 100)
        if (amount > value) {
            return { code: 'id_amount_above_maximum_allowed', value, visible: true }
        }
        return null
    }

    ReceiveAddressController {
        id: controller
        context: self.context
        session: controller.account.session
        account: self.account
        asset: self.asset
        convert.unit: controller.account.session.unit
    }
    SwapQuoteController {
        id: quote_controller
        context: self.context
        sendNetworkKey: 'lightning'
        receiveNetworkKey: 'liquid'
    }
    Connections {
        enabled: self.invoice
        target: amount_field.convert
        function onResultChanged() {
            quote_controller.send(amount_field.convert.result?.satoshi ?? 0)
        }
    }

    InvoiceController {
        id: invoice_controller
        context: self.context
        address: controller.address?.address ?? ''
        satoshi: quote_controller.quote?.send_amount ?? ''
    }
    Connections {
        enabled: self.invoice
        target: invoice_controller
        function onSwapChanged() {
            if (!invoice_controller.swap) {
                self.invoicePushed = false
                return
            }
            if (self.invoicePushed) return

            self.openLightningInvoice()
        }
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
    footerItem: RowLayout {
        spacing: 20
        RegularButton {
            Layout.fillWidth: true
            id: more_options_button
            text: qsTrId('id_more_options')
            visible: !self.invoice
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
            enabled: !controller.generating && (controller.context.device?.connected ?? false) && !self.invoice
            text: qsTrId('id_verify_on_device')
            visible: controller.context.wallet.login.device?.type === 'jade'
            onClicked: {
                self.pushPage(jade_verify_page, { context: self.context, address: controller.address })
                Analytics.recordEvent('verify_address', AnalyticsJS.segmentationSubAccount(Settings, controller.account))
            }
        }
        PrimaryButton {
            Layout.fillWidth: true
            id: confirm_button
            busy: invoice_controller.busy
            enabled: !confirm_button.busy && !self.error
            text: qsTrId('id_create_invoice')
            visible: self.invoice
            onClicked: {
                if (invoice_controller.swap) {
                    self.openLightningInvoice()
                    return
                }
                Analytics.recordEvent('swap_receive', AnalyticsJS.segmentationSwap(Settings, self.context, {
                    from: 'lightning',
                    to: 'liquid'
                }))
                invoice_controller.request()
            }
        }
    }
    contentItem: VFlickable {
        alignment: Qt.AlignTop
        spacing: 5
        FieldTitle {
            Layout.topMargin: 0
            text: qsTrId('id_account__asset')
            visible: !self.lockAssetAndAccount
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
            visible: !self.lockAssetAndAccount
            onClicked: self.pushPage(account_asset_selector)
        }
        FieldTitle {
            text: qsTrId('Payer Sends')
            visible: self.lightningEnabled
        }
        Pane {
            Layout.fillWidth: true
            padding: 0
            visible: self.lightningEnabled
            background: Rectangle {
                border.width: 0.5
                border.color: '#313131'
                color: '#121414'
                radius: 4
            }
            contentItem: RowLayout {
                Option {
                    id: liquid_option
                    text: 'Liquid'
                    checked: !self.invoice
                    onClicked: {
                        self.invoice = false
                        self.invoicePushed = false
                        amount_field.visible = false
                        amount_field.clearText()
                    }
                }
                Option {
                    id: lightning_option
                    text: 'Lightning'
                    checked: self.invoice
                    onClicked: {
                        Analytics.recordEvent('swap_toggle', AnalyticsJS.segmentationSwap(Settings, self.context, {
                            from: 'lightning',
                            to: 'liquid'
                        }))
                        self.invoice = true
                        self.invoicePushed = false
                        amount_field.visible = true
                        amount_field.clearText()
                        amount_field.forceActiveFocus()
                    }
                }
            }
        }
        component Option: AbstractButton {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            id: option
            implicitHeight: 35
            background: Item {
                Rectangle {
                    anchors.fill: parent
                    visible: option.checked
                    border.width: option.checked ? 1 : 0.5
                    border.color: Qt.alpha('#FFF', 0.3)
                    color: '#3A3A3D'
                    radius: 4
                }
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -4
                    border.width: 2
                    border.color: '#00BCFF'
                    color: 'transparent'
                    radius: 8
                    visible: option.visualFocus
                }
            }
            contentItem: Label {
                font.pixelSize: 12
                font.weight: 600
                horizontalAlignment: Label.AlignHCenter
                verticalAlignment: Label.AlignVCenter
                opacity: option.checked ? 1 : 0.3
                text: option.text
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
            error: error_pane.expanded ? self.error : null
            session: controller.account.session
            visible: false
        }
        Convert {
            id: error_value_convert
            asset: self.asset
            context: self.context
            input: ({ satoshi: String(self.error?.value ?? 0) })
            unit: amount_field.convert.unit
        }
        ErrorPane {
            Layout.topMargin: -15
            id: error_pane
            error: self.error && self.error.visible ? qsTrId(self.error?.code) + ' - ' + (amount_field.fiat ? '~ ' + error_value_convert.fiat.label : error_value_convert.output.label) : null
        }
        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            color: '#A0A0A0'
            font.pixelSize: 12
            font.weight: 400
            horizontalAlignment: Label.AlignHCenter
            visible: self.invoice && !self.error
            text: 'Amount to receive: ' + (amount_field.fiat ? amount_to_receive.fiat.label : amount_to_receive.output.label)
            wrapMode: Label.WordWrap
        }
        Convert {
            id: amount_to_receive
            asset: self.asset
            context: self.context
            input: ({ satoshi: quote_controller.quote?.receive_amount ?? 0 })
            unit: amount_field.convert.unit
        }
        FieldTitle {
            text: self.invoice ? qsTrId('id_invoice') : qsTrId('id_account_address')
            visible: !controller.error && !self.invoice
        }
        ErrorPane {
            error: controller.error || null
            visible: !self.invoice
        }
        Pane {
            Layout.fillWidth: true
            padding: 20
            visible: !controller.error && !self.invoice
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
                        text: self.qrcode
                        implicitHeight: 192
                        implicitWidth: 192
                        radius: 8
                        border: 0
                        color: '#00BCFF'
                        corners: true
                        AssetIcon {
                            anchors.centerIn: parent
                            asset: controller.asset
                            size: 24
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
                            visible: !self.invoice
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
                        onClicked: self.pushPage(qrcode_page)
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
        VSpacer {
        }
        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            color: '#A0A0A0'
            font.pixelSize: 12
            font.weight: 400
            horizontalAlignment: Label.AlignHCenter
            text: 'You will receive Liquid Bitcoin via Lightning invoice.'
            visible: self.invoice
            wrapMode: Label.WordWrap
        }
    }

    Component {
        id: jade_verify_page
        JadeVerifyAddressPage {
        }
    }

    Component {
        id: lightning_invoice_page
        LightningInvoicePage {
            context: self.context
            asset: self.asset
            footerMessage: 'You will receive Liquid Bitcoin via Lightning invoice.'
            onCloseClicked: self.closeClicked()
        }
    }

    Component {
        id: qrcode_page
        StackViewPage {
            title: qsTrId('id_qr_code')
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
                    text: self.qrcode
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
            onCloseClicked: self.closeClicked()
            onSelected: (account, asset) => {
                self.account = account
                self.asset = asset
                amount_field.text = '0'
                self.popPage(self)
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
            text: qsTrId('id_list_of_addresses')
            icon.source: 'qrc:/svg2/list_bullets.svg'
            onClicked: {
                menu.close()
                self.pushPage(addresses_page, { account: controller.account })
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
        onClicked: self.pushPage(address_details_page, { context: self.context, address: delegate.address })
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
