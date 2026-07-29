import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS

StackViewPage {
    required property Context context
    
    property bool invoicePushed: false
    property bool noteEditable: controller.description.length > 0

    readonly property Asset asset: self.context.getOrCreateAsset('lnbtc')
    readonly property bool isLimitsError: controller.error === 'minimum' || controller.error === 'maximum'
    readonly property bool isWarning: controller.validationState === 'warning'
    readonly property bool isInfo: controller.validationState === 'info'

    function amountLabel(convert) {
        const output = convert.output.label
        return convert.fiat.available
            ? `${output} (~ ${convert.fiat.label})`
            : output
    }

    StackView.onActivated: amount_field.forceActiveFocus()

    id: self
    title: qsTrId('id_receive')
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    footerItem: PrimaryButton {
        Layout.fillWidth: true
        busy: controller.busy
        enabled: controller.canCreate
        text: qsTrId('id_create_invoice')
        onClicked: controller.createInvoice()
    }

    LightningReceiveController {
        id: controller
        context: self.context
        description: note_text_area.text.trim()
    }

    Connections {
        target: controller
        function onUpdated() {
            if (controller.invoice.length === 0) {
                self.invoicePushed = false
            }
            
            if (self.invoicePushed || controller.invoice.length === 0) return

            self.invoicePushed = true
            Analytics.recordEvent('invoice_create', AnalyticsJS.segmentationLightning(Settings, self.context))
            self.StackView.view.push(lightning_invoice_page, {
                invoice: controller.invoice,
                amountSats: Number(controller.satoshi),
                fundingFeeSats: controller.openingFeeSatoshi,
                expiresAt: controller.expiresAt,
                note: controller.description.trim(),
            })
        }
    }

    Convert {
        id: amount_convert
        asset: self.asset
        context: self.context
        unit: self.context.primarySession.unit
    }
    Convert {
        id: minimum_convert
        asset: self.asset
        context: self.context
        input: ({ satoshi: String(controller.minSatoshi ?? 0) })
        unit: amount_field.unit
    }
    Convert {
        id: maximum_convert
        asset: self.asset
        context: self.context
        input: ({ satoshi: String(controller.maxSatoshi ?? 0) })
        unit: amount_field.unit
    }
    Convert {
        id: recommended_convert
        asset: self.asset
        context: self.context
        input: ({ satoshi: String(controller.recommendedSatoshi ?? 0) })
        unit: amount_field.unit
    }

    Connections {
        target: amount_convert
        function onResultChanged() {
            controller.satoshi = amount_convert.result?.satoshi ?? ''
        }
    }

    contentItem: VFlickable {
        alignment: Qt.AlignTop
        spacing: 5

        FieldTitle {
            Layout.topMargin: 0
            text: qsTrId('id_asset')
        }
        Pane {
            Layout.fillWidth: true
            padding: 20
            background: Rectangle {
                border.color: '#262626'
                border.width: 1
                color: '#181818'
                radius: 5
            }
            contentItem: RowLayout {
                spacing: 12
                AssetIcon {
                    asset: self.asset
                    size: 32
                }
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    color: '#FFFFFF'
                    font.pixelSize: 16
                    font.weight: 600
                    text: self.asset.name
                    elide: Label.ElideRight
                }
            }
        }

        FieldTitle {
            text: 'Receive Amount'
        }
        AmountField {
            Layout.fillWidth: true
            id: amount_field
            session: self.context.primarySession
            borderWidth: isLimitsError || isWarning || isInfo ? 1 : 0
            borderColor: {
                if (isLimitsError) return '#82181A'
                if (isWarning) return '#7E2A0D'
                if (isInfo) return '#004A70'
                return '#262626'
            }
            convert: amount_convert
        }
        MessagePane {
            Layout.topMargin: -15
            variant: controller.validationState
            linkVisible: isWarning || isInfo
            text: {
                if (controller.error === 'minimum') return 'Minimum is %1.'.arg(self.amountLabel(minimum_convert))
                if (controller.error === 'maximum') return 'Maximum is %1.'.arg(self.amountLabel(maximum_convert))
                if (isWarning) return 'Recommended amount is at least %1 to avoid high funding fees.'.arg(self.amountLabel(recommended_convert))
                if (isInfo) return 'Requires a funding fee.'
                return controller.error ?? ''
            }
        }
        LinkButton {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 20
            text: qsTrId('id_add_note')
            visible: !self.noteEditable
            onClicked: {
                self.noteEditable = true
                note_text_area.forceActiveFocus()
            }
        }
        FieldTitle {
            text: qsTrId('id_note')
            visible: self.noteEditable
        }
        GTextArea {
            Layout.fillWidth: true
            id: note_text_area
            visible: self.noteEditable
            wrapMode: TextArea.Wrap
        }
        VSpacer {
        }
    }

    Component {
        id: lightning_invoice_page
        LightningInvoicePage {
            context: self.context
            onCloseClicked: self.closeClicked()
        }
    }

    component MessagePane: Item {
        required property string variant
        required property string text
        required property bool linkVisible

        readonly property string helpUrl: 'https://help.blockstream.com/hc/en-us/articles/18788499177753-Understand-receive-capacity-and-funding-fees-on-your-Instant-Lightning-account'
        readonly property string formattedText: message_pane.linkVisible
            ? '%1 <b><a href="%2" style="color:#FFFFFF">Learn why</a></b>.'
                .arg(message_pane.text)
                .arg(message_pane.helpUrl)
            : message_pane.text

        readonly property var colors: {
            switch (message_pane.variant) {
                case 'info': return { fill: '#062F4A', stroke: '#004A70' }
                case 'warning': return { fill: '#432004', stroke: '#7E2A0D' }
                case 'error': return { fill: '#460708', stroke: '#82181A' }
                default: return { fill: '#062F4A', stroke: '#004A70' }
            }
        }

        Layout.fillWidth: true
        id: message_pane
        implicitHeight: message_pane.visible ? pane.implicitHeight : 0
        visible: message_pane.text.length > 0
        z: -1

        Pane {
            id: pane
            width: message_pane.width
            padding: 12
            topPadding: 24
            background: Rectangle {
                border.color: message_pane.colors.stroke
                border.width: 1
                color: message_pane.colors.fill
                radius: 5
            }
            contentItem: Label {
                id: message_label
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                color: '#FFFFFF'
                font.pixelSize: 14
                font.weight: 400
                linkColor: '#FFFFFF'
                text: message_pane.formattedText
                textFormat: Text.RichText
                wrapMode: Label.WordWrap
                onLinkActivated: (link) => Qt.openUrlExternally(link)
                HoverHandler {
                    cursorShape: message_label.hoveredLink.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                }
            }
        }
    }
}
