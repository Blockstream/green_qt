import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12
import '..'

ColumnLayout {
    property string title: qsTrId('id_advanced')

    spacing: 30

    SettingsBox {
        title: 'PGP'
        description: qsTr('id_add_a_pgp_public_key_to_receive')

        FlatButton {
            Layout.alignment: Qt.AlignRight
            text: qsTr('id_pgp_key')
        }
    }
}
