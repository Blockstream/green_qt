import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12
import '..'

ColumnLayout {
    spacing: 30

    SettingsBox {
        title: 'PGP'
        subtitle: 'Set your PGP key for improved privacy'

        FlatButton {
            text: qsTr('Add PGP key')
        }
    }
}
