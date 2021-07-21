import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

ControllerDialog {
    id: dialog

    property var currencies: [{
        is_fiat: false,
        text: wallet.settings.unit
    }, {
        is_fiat: true,
        text: wallet.settings.pricing.currency
    }]

    readonly property string unit: {
        const unit = wallet.settings.unit
        return unit === '\u00B5BTC' ? 'ubtc' : unit.toLowerCase()
    }

    property string threshold: wallet.config.limits.is_fiat ? wallet.config.limits.fiat : wallet.config.limits[unit]
    property string ticker: wallet.config.limits.is_fiat ? wallet.settings.pricing.currency : unit

    title: qsTrId('id_set_twofactor_threshold')
    doneText: qsTrId('id_your_twofactor_threshold_is_s').arg(threshold + ' ' +  ticker)
    controller: Controller {
        wallet: dialog.wallet
    }
    initialItem: WizardPage {
        actions: Action {
            text: qsTrId('id_next')
            onTriggered: controller.changeTwoFactorLimit(currency_combo.fiat, amount_field.text)
        }

        contentItem: GridLayout {
            columns: 2
            rowSpacing: constants.s1
            columnSpacing: constants.s1

            Label {
                text: qsTrId('id_currency')
            }

            GComboBox {
                property bool fiat: model[currentIndex].is_fiat
                id: currency_combo
                currentIndex: wallet.config.limits.is_fiat ? 1 : 0
                model: currencies
                textRole: 'text'
                Layout.fillWidth: true
            }

            Label {
                text: qsTrId('id_amount')
            }

            GTextField {
                id: amount_field
                text: threshold
                padding: 10
                Layout.fillWidth: true
            }

            VSpacer {
            }
        }
    }
}
