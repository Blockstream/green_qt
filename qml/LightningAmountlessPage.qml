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
    readonly property bool errorVisible: amount_field.text.length > 0 && self.controller.error.length > 0

    StackView.onActivated: amount_field.forceActiveFocus()

    id: self
    title: qsTrId('id_amount')
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    footerItem: PrimaryButton {
        Layout.fillWidth: true
        enabled: amount_field.text.length > 0 && !self.errorVisible
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
            error: self.errorVisible
        }
        ErrorPane {
            Layout.topMargin: -15
            error: self.controller.error
        }
        VSpacer {
        }
    }
}
