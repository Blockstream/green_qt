import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Layouts
import QtQml.Models

import "util.js" as UtilJS

GPane {
    required property bool showAMP
    required property string view

    id: self
    contentItem: RowLayout {
        spacing: 12
        HSpacer {
        }
        Section {
            visible: navigation.param.flow === self.view && (!navigation.param.network || navigation.param.network === 'mainnet')
            title: 'Bitcoin Network'
            contentItem: RowLayout {
                spacing: 12
                SelectNetworkViewCard {
                    network: 'bitcoin'
                    type: 'default'
                    icons: [UtilJS.iconFor('bitcoin')]
                    title: 'Bitcoin Wallet'
                    description: qsTrId('id_bitcoin_is_the_worlds_leading')
                }
            }
        }
        Section {
            visible: navigation.param.flow === self.view || navigation.param.network === 'liquid'
            title: 'Liquid Network'
            contentItem: RowLayout {
                spacing: 12
                SelectNetworkViewCard {
                    network: 'liquid'
                    type: 'default'
                    icons: [UtilJS.iconFor('liquid')]
                    title: qsTrId('id_liquid_wallet')
                    description: qsTrId('id_the_liquid_network_is_a_bitcoin')
                }
                SelectNetworkViewCard {
                    visible: self.showAMP
                    network: 'liquid'
                    type: 'amp'
                    icons: ['qrc:/svg/amp.svg']
                    title: qsTrId('id_amp_wallet')
                    description: qsTrId('id_amp_accounts_are_only_available')
                }
            }
        }
        HSpacer {
        }
    }

    component Section: Page {
        id: section
        bottomPadding: 12
        header: Label {
            bottomPadding: 12
            topPadding: 12
            opacity: 0.5
            text: section.title
        }
        background: null
    }
}
