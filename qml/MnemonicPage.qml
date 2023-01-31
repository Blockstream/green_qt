import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

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
    GPane {
        id: view_pane
        visible: false
        padding: 16
        contentItem: MnemonicView {
            Layout.alignment: Qt.AlignHCenter
            id: view
        }
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
    GaussianBlur {
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: view_pane.implicitWidth
        implicitHeight: view_pane.implicitHeight
        source: view_pane
        samples: 16
        radius: window.active ? 0 : 8
        Behavior on radius {
            SmoothedAnimation {
                velocity: 20
            }
        }
    }
    VSpacer {
    }
}
