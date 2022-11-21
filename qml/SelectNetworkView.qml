import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.15
import QtQml 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQml.Models 2.0

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
            visible: navigation.path === `/${view}` || navigation.path === `/mainnet/${view}`
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
            visible: navigation.path === `/${view}` || navigation.path === `/liquid/${view}`
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
