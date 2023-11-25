import Blockstream.Green
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    property string title: qsTrId('id_advanced')

    spacing: 30

    SettingsBox {
        title: 'PGP'
        description: qsTrId('id_add_a_pgp_public_key_to_receive')

        GButton {
            large: true
            Layout.alignment: Qt.AlignRight
            text: qsTrId('id_pgp_key')
        }
    }
}
