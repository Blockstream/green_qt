import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS

StackViewPage {
    required property Context context
    required property LightningLnurlController controller

    readonly property Asset asset: self.context.getOrCreateAsset('lnbtc')
    readonly property var request: self.controller.request
    readonly property string domain: self.request?.domain ?? ''
    readonly property string address: self.domain || self.request?.lnurl || ''
    readonly property bool addressIsDomain: self.domain !== ''
    readonly property var amountSatoshi: Number(self.controller.enteredSatoshi)
    readonly property var successAction: self.controller.successAction
    readonly property string successActionType: self.successAction?.type ?? ''
    readonly property string successActionMessage: {
        if (self.successActionType === 'message') return self.successAction?.message ?? ''
        if (self.successActionType === 'aes') {
            const description = self.successAction?.description ?? ''
            const plaintext = self.successAction?.plaintext ?? ''
            if (description && plaintext) return description + '\n' + plaintext
            return plaintext || description
        }
        return self.successAction?.description ?? ''
    }
    readonly property string successActionUrl: self.successActionType === 'url' ? (self.successAction?.url ?? '') : ''

    id: self
    title: qsTrId('id_confirm_transaction')
    leftItem: BackButton {
        enabled: !self.controller.busy
        onClicked: self.popPage()
    }
    rightItem: CloseButton {
        enabled: !self.controller.busy
        onClicked: self.closeClicked()
    }
    footerItem: PrimaryButton {
        Layout.fillWidth: true
        busy: self.controller.busy
        enabled: self.controller.canPay
        text: qsTrId('id_send')
        onClicked: {
            Analytics.recordEvent('send_attempt', AnalyticsJS.segmentationLightning(self.context, { invoice_type: 'lnurl' }))
            self.controller.pay()
        }
    }

    Connections {
        target: self.controller
        function onPaid() {
            Settings.registerEvent({ invoice: self.controller.input })
            Analytics.recordEvent('send_transaction', AnalyticsJS.segmentationLightning(self.context, { invoice_type: 'lnurl' }))
            self.pushPage(transaction_completed_page)
        }
        function onFailed(error) {
            const segmentation = AnalyticsJS.segmentationLightning(self.context, { invoice_type: 'lnurl' })
            segmentation.error = error
            segmentation.node_id = self.context.lightningNodeInfo?.id ?? ''
            Analytics.recordEvent('failed_transaction', segmentation)
            self.pushPage(transaction_failed_page, { error })
        }
    }

    Convert {
        id: amount_convert
        asset: self.asset
        context: self.context
        input: ({ satoshi: String(self.amountSatoshi ?? 0) })
        unit: self.context.primarySession.unit
    }
    Convert {
        id: success_amount_convert
        asset: self.asset
        context: self.context
        input: ({ satoshi: String(self.amountSatoshi ?? 0) })
        unit: self.context.primarySession.unit
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
            text: qsTrId('id_recipient')
            visible: self.address !== ''
        }
        Label {
            Layout.fillWidth: true
            color: '#FFFFFF'
            elide: Label.ElideMiddle
            font.pixelSize: 16
            font.weight: 400
            horizontalAlignment: Text.AlignHCenter
            padding: 20
            text: self.address
            visible: self.addressIsDomain
            wrapMode: Label.Wrap
            background: Rectangle {
                color: '#181818'
                radius: 5
            }
        }
        AddressLabel {
            Layout.fillWidth: true
            address: self.address
            accentColor: '#DFB316'
            padding: 20
            visible: self.address !== '' && !self.addressIsDomain
            background: Rectangle {
                color: '#181818'
                radius: 5
            }
        }
        FieldTitle {
            text: qsTrId('id_description')
            visible: (self.request?.description ?? '') !== ''
        }
        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            color: '#FFFFFF'
            font.pixelSize: 14
            font.weight: 400
            padding: 20
            text: self.request?.description ?? ''
            visible: text !== ''
            wrapMode: Label.Wrap
            background: Rectangle {
                color: '#181818'
                radius: 5
            }
        }
        FieldTitle {
            text: qsTrId('id_amount')
        }
        AmountField {
            Layout.fillWidth: true
            readOnly: true
            session: self.context.primarySession
            convert: amount_convert
        }
        FieldTitle {
            text: qsTrId('id_comment')
            visible: (self.controller.comment ?? '') !== ''
        }
        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            color: '#FFFFFF'
            font.pixelSize: 14
            font.weight: 400
            padding: 20
            text: self.controller.comment
            visible: text !== ''
            wrapMode: Label.Wrap
            background: Rectangle {
                color: '#181818'
                radius: 5
            }
        }
        ErrorPane {
            error: self.controller.error
        }
        VSpacer {
        }
    }

    Component {
        id: transaction_completed_page
        TransactionCompletedPage {
            message: qsTr('You transferred %1').arg(success_amount_convert.output.label)
            successActionMessage: self.successActionMessage
            successActionUrl: self.successActionUrl
            onCloseClicked: self.closeClicked()
        }
    }
    Component {
        id: transaction_failed_page
        TransactionFailedPage {
            onCloseClicked: self.closeClicked()
        }
    }
}
