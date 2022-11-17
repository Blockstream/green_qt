import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.15
import QtQml 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQml.Models 2.0

import "analytics.js" as AnalyticsJS

Page {
    id: self
    background: null
    contentItem: RowLayout {
        spacing: 24
        DiscoverServerTypeViewCard {
            id: singlesig_card
            server_type: 'electrum'
            icons: ['qrc:/svg/singleSig.svg']
            title: qsTrId('id_singlesig')
            visible: navigation.param.type !== 'amp' && (navigation.param.password || '') === ''
        }
        DiscoverServerTypeViewCard {
            id: multisig_card
            server_type: 'green'
            icons: ['qrc:/svg/multi-sig.svg']
            title: qsTrId('id_multisig_shield')
        }
    }
    footer: DialogFooter {
        leftPadding: 0
        rightPadding: 0
        bottomPadding: constants.p2
        GButton {
            large: true
            text: qsTrId('id_back')
            onClicked: navigation.pop()
        }
        HSpacer {
        }
        CheckBox {
            id: advanced_checkbox
            visible: singlesig_card.active && singlesig_card.noErrors && multisig_card.noErrors
            enabled: !(singlesig_card.busy || multisig_card.busy) && !(singlesig_card.valid && multisig_card.valid) && !(multisig_card.wallet && singlesig_card.wallet)
            text: qsTrId('id_show_advanced_options')
        }
    }
}
