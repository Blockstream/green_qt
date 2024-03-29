import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Layouts
import QtQml.Models

GPane {
    id: self
    contentItem: RowLayout {
        spacing: 24
        HSpacer {
        }
        SelectServerTypeViewCard {
            server_type: 'electrum'
            icons: ['qrc:/svg2/singlesig.svg']
            title: qsTrId('Singlesig')
            description: qsTrId('id_your_funds_are_secured_by_a')
        }
        SelectServerTypeViewCard {
            enabled: (navigation.param.type || '') !== 'amp'
            server_type: 'green'
            icons: ['qrc:/svg/home.svg']
            title: 'Multisig Shield'
            description: qsTrId('id_your_funds_are_secured_by')
        }
        HSpacer {
        }
    }
}
