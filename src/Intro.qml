import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

GridLayout {

    function filter(network) {
        const search = search_field.text.trim().toLowerCase();
        const result = [];
        for (let i = 0; i < WalletManager.wallets.length; i++) {
            const wallet = WalletManager.wallets[i];
            if (network && wallet.network.id !== network) continue;
            if (search.length > 0 && wallet.name.toLowerCase().indexOf(search) < 0) continue;
            result.push(wallet);
        }
        return result.sort((a, b) => a.name.localeCompare(b.name));
    }

    columns: 2

    Image {
        id: logo
        source: 'assets/svg/logo_big.svg'
        scale: 0.5
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 256
        TabBar {
            id: networks_tab_bar
            Layout.alignment: Qt.AlignBottom
            TabButton {
                property var model: filter()
                width: 128
                text: qsTrId('id_wallets')
            }
        }
        TextField {
            id: search_field
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.alignment: Qt.AlignBottom
            placeholderText: qsTrId('id_search')
        }
    }

    ColumnLayout {
        Layout.alignment: Qt.AlignTop
        Layout.minimumWidth: 256
        Layout.leftMargin: 16
        Button {
            flat: true
            text: qsTr('id_create_new_wallet')
            action: create_wallet_action
        }
        Button {
            flat: true
            action: restore_wallet_action
        }
    }

    RowLayout {
        ListView {
            spacing: 8
            clip: true
            model: networks_tab_bar.currentItem.model
            delegate: ItemDelegate {
                width: parent.width
                icon.source: icons[modelData.network.id]
                icon.color: 'transparent'
                text: modelData.name
                onClicked: currentWallet = modelData
                highlighted: modelData.connection !== Wallet.Disconnected
            }

            Layout.fillWidth: true
            Layout.fillHeight: true

            ScrollBar.vertical: ScrollBar { }

            ScrollShadow {}
        }
    }
}
