import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    signal nextClicked()

    required property Context context
    required property LightningSendController controller

    readonly property Asset asset: self.context.getOrCreateAsset('lnbtc')
    readonly property bool amountEntered: amount_field.text.length > 0
    readonly property double enteredSatoshi: Number(amount_convert.result?.satoshi ?? 0)
    readonly property string amountError: {
        if (!self.amountEntered) return ''
        if (self.enteredSatoshi <= 0) return 'id_invalid_amount'
        return self.controller.error
    }

    StackView.onActivated: amount_field.forceActiveFocus()

    id: self
    title: qsTrId('id_amount')
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    footerItem: PrimaryButton {
        Layout.fillWidth: true
        enabled: self.amountEntered && self.enteredSatoshi > 0 && !self.amountError
        text: qsTrId('id_next')
        onClicked: self.nextClicked()
    }

    Convert {
        id: amount_convert
        asset: self.asset
        context: self.context
        unit: self.context.primarySession.unit
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
        FieldTitle {
            Layout.topMargin: 0
            text: qsTrId('id_amount')
        }
        AmountField {
            Layout.fillWidth: true
            id: amount_field
            session: self.context.primarySession
            convert: amount_convert
            error: self.amountError
        }
        ErrorPane {
            Layout.topMargin: -15
            error: self.amountError
        }
        VSpacer {
        }
    }
}
