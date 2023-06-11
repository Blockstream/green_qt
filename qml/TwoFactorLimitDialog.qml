import Blockstream.Green
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

ControllerDialog {
    id: self

    required property Session session

    property var currencies: [{
        is_fiat: false,
        text: self.session.unit
    }, {
        is_fiat: true,
        text: self.session.settings.pricing.currency
    }]

    readonly property string unit: {
        const unit = self.session.unit
        return unit === '\u00B5BTC' ? 'ubtc' : unit.toLowerCase()
    }

    property string threshold: self.session.config.limits.is_fiat ? self.session.config.limits.fiat : self.session.config.limits[unit]
    property string ticker: self.session.config.limits.is_fiat ? self.session.settings.pricing.currency : unit

    title: qsTrId('id_set_twofactor_threshold')

    // TODO
    // doneText: qsTrId('id_your_twofactor_threshold_is_s').arg(threshold + ' ' +  ticker)

    controller: Controller {
        id: controller
        context: self.context
    }

    ColumnLayout {
        GridLayout {
            columns: 2
            rowSpacing: constants.s1
            columnSpacing: constants.s1

            Label {
                text: qsTrId('id_currency')
            }

            GComboBox {
                property bool fiat: model[currentIndex].is_fiat
                id: currency_combo
                currentIndex: self.session.config.limits.is_fiat ? 1 : 0
                model: self.currencies
                textRole: 'text'
                Layout.fillWidth: true
            }

            Label {
                text: qsTrId('id_amount')
            }

            GTextField {
                id: amount_field
                text: self.threshold
                padding: 10
                Layout.fillWidth: true
            }
        }
        VSpacer {
        }
        GButton {
            Layout.alignment: Qt.AlignRight
            highlighted: true
            large: true
            text: qsTrId('id_next')
            onClicked: controller.changeTwoFactorLimit(currency_combo.fiat, amount_field.text)
        }
    }
}
