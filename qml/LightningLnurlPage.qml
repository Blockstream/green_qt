import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    signal nextClicked()

    required property Context context
    required property LightningLnurlController controller

    readonly property Asset asset: self.context.getOrCreateAsset('lnbtc')
    readonly property bool amountEntered: amount_field.text.length > 0
    readonly property double enteredSatoshi: Number(amount_convert.result?.satoshi ?? 0)
    readonly property var request: self.controller.request
    readonly property string domain: self.request?.domain ?? ''
    readonly property string address: self.domain || self.request?.lnurl || ''
    readonly property bool addressIsDomain: self.domain !== ''
    readonly property var amountError: {
        if (!self.amountEntered) return null
        if (self.enteredSatoshi <= 0) return { text: 'id_invalid_amount', amount: 0 }
        const error = self.controller.amountError
        return error?.text ? error : null
    }
    readonly property string displayError: {
        if (self.controller.error) return UtilJS.formatError(self.controller.error)
        if (self.controller.commentError) return UtilJS.formatError(self.controller.commentError)
        if (!self.amountError) return ''
        if (Number(self.amountError.amount ?? 0) > 0) {
            const amount = amount_field.fiat ? '~ ' + error_value_convert.fiat.label : error_value_convert.output.label
            return UtilJS.formatError(self.amountError.text) + ' - ' + amount
        }
        return UtilJS.formatError(self.amountError.text)
    }

    StackView.onActivated: amount_field.forceActiveFocus()

    id: self
    title: qsTrId('id_lightning_invoice__lnurl')
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
        enabled: self.controller.canContinue
        text: qsTrId('id_next')
        onClicked: self.nextClicked()
    }

    Convert {
        id: amount_convert
        asset: self.asset
        context: self.context
        unit: self.context.primarySession.unit
    }
    Convert {
        id: error_value_convert
        asset: self.asset
        context: self.context
        input: ({ satoshi: String(self.amountError?.amount ?? 0) })
        unit: amount_field.convert.unit
    }
    Connections {
        target: amount_convert
        function onResultChanged() {
            self.controller.enteredSatoshi = amount_convert.result?.satoshi ?? ''
        }
    }

    contentItem: VFlickable {
        alignment: Qt.AlignTop
        spacing: 5
        Image {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 64
            Layout.preferredWidth: 64
            fillMode: Image.PreserveAspectFit
            source: self.request?.image ?? ''
            visible: (self.request?.image ?? '') !== ''
        }
        FieldTitle {
            Layout.topMargin: 0
            text: qsTrId('id_address')
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
            id: amount_field
            enabled: !self.controller.busy
            error: self.amountError
            session: self.context.primarySession
            convert: amount_convert
        }
        ErrorPane {
            Layout.topMargin: -15
            error: self.displayError
        }
        FieldTitle {
            text: qsTrId('id_comment')
            visible: Number(self.request?.commentAllowed ?? 0) > 0
        }
        TTextField {
            Layout.fillWidth: true
            id: comment_field
            enabled: !self.controller.busy
            error: self.controller.commentError
            maximumLength: Number(self.request?.commentAllowed ?? 0)
            visible: Number(self.request?.commentAllowed ?? 0) > 0
            onTextChanged: self.controller.comment = comment_field.text
        }
        VSpacer {
        }
    }
}
