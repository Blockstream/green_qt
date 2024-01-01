import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    property alias mnemonic: view.mnemonic
    property int mnemonicSize: size_combobox.currentValue
    spacing: 20
    VSpacer {
    }
    Label {
        Layout.alignment: Qt.AlignHCenter
        text: qsTrId('id_write_down_your_recovery_phrase')
        font.pixelSize: 20
    }
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        Layout.fillWidth: true
        spacing: constants.s1
        Label {
            text: qsTrId('id_choose_recovery_phrase_length')
        }
        GComboBox {
            id: size_combobox
            Layout.minimumWidth: 120
            model: [
                { value: 12, text: qsTrId('id_d_words').arg(12) },
                { value: 24, text: qsTrId('id_d_words').arg(24) },
            ]
            textRole: 'text'
            valueRole: 'value'
        }
    }
    GPane {
        Layout.alignment: Qt.AlignHCenter
        padding: 16
        contentItem: MnemonicView {
            Layout.alignment: Qt.AlignHCenter
            id: view
        }
    }
    VSpacer {
    }
}
