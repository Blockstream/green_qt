import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.15
import QtQml 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQml.Models 2.0

GPane {
    id: self
    contentItem: RowLayout {
        spacing: 24
        HSpacer {
        }
        SelectServerTypeViewCard {
            server_type: 'electrum'
            icons: ['qrc:/svg/singleSig.svg']
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
