import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

ControllerDialog {
    title: qsTrId('id_set_locktime')
    controller: SettingsController {}
    initialItem: ColumnLayout {
        property list<Action> actions: [
            Action {
                text: qsTrId('id_ok')
                enabled: !isNaN(Number.parseInt(nlocktime_field.text)) && Number.parseInt(nlocktime_field.text).toString() === nlocktime_field.text
                onTriggered: controller.change({ nlocktime: Number.parseInt(nlocktime_field.text) })
            }
        ]
        SectionLabel {
            text: qsTrId('id_blocks')
        }
        TextField {
            id: nlocktime_field
            text: wallet.settings.nlocktime || 0
        }
        Label {
            readonly property int days: Math.round(nlocktime_field.text / 144)
            readonly property string duration: {
                if (days < 32) return `${days} days`;
                const weeks = Math.round(nlocktime_field.text / 144 / 7);
                if (weeks < 9) return `${weeks} weeks`;
                const months = Math.round(nlocktime_field.text / 144 / 30);
                if (months < 12) return `${months} months`;
                const years = Math.round(nlocktime_field.text / 144 / 365);
                return `${years} years`;
            }
            text: '≈ ' + duration
        }
    }
}
