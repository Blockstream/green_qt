import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.14
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

ColumnLayout {
    id: account_view
    spacing: constants.p3
    required property Account account

    function getUnblindingData(tx) {
        return {
            version: 0,
            txid: tx.txhash,
            type: tx.type,
            inputs: tx.inputs
                .filter(i => i.asset_id && i.satoshi && i.assetblinder && i.amountblinder)
                .map(i => ({
                   vin: i.pt_idx,
                   asset_id: i.asset_id,
                   assetblinder: i.assetblinder,
                   satoshi: i.satoshi,
                   amountblinder: i.amountblinder,
                })),
            outputs: tx.outputs
                .filter(o => o.asset_id && o.satoshi && o.assetblinder && o.amountblinder)
                .map(o => ({
                   vout: o.pt_idx,
                   asset_id: o.asset_id,
                   assetblinder: o.assetblinder,
                   satoshi: o.satoshi,
                   amountblinder: o.amountblinder,
                })),
        }
    }

    function copyUnblindingData(item, tx) {
        Clipboard.copy(JSON.stringify(getUnblindingData(tx), null, '  '))
        item.ToolTip.show(qsTrId('id_copied_to_clipboard'), 2000);
    }

    RowLayout {
        id: toolbar
        Layout.fillWidth: true
        spacing: constants.p1
        ButtonGroup {
            id: button_group
            onCheckedButtonChanged: {
                let index = -1
                let size = button_group.buttons.length
                if (!account_view.account.wallet.network.liquid) size -= 2 // if account is not liquid ignore the first two buttons
                for (let i = 0; i < size; ++i) {
                    let child = button_group.buttons[i]
                    if (child.enabled && child.checked) index = button_group.buttons.length-i-1
                }
                if (index>-1) stack_layout.currentIndex = index
            }
        }
        TabButton {
            checked: account_view.account.wallet.network.liquid
            ButtonGroup.group: button_group
            enabled: account_view.account.wallet.network.liquid
            visible: enabled
            icon.source: "qrc:/svg/overview.svg"
            ToolTip.text: qsTrId('id_overview')
            onClicked: checked = true
        }
        TabButton {
            id: assets_toolbar_button
            ButtonGroup.group: button_group
            enabled: account_view.account.wallet.network.liquid
            visible: enabled
            icon.source: "qrc:/svg/assets.svg"
            ToolTip.text: qsTrId('id_assets')
            onClicked: checked = true
        }
        TabButton {
            id: transactions_toolbar_button
            checked: !account_view.account.wallet.network.liquid
            ButtonGroup.group: button_group
            icon.source: "qrc:/svg/transactions.svg"
            ToolTip.text: qsTrId('id_transactions')
            onClicked: checked = true
        }
        TabButton {
            ButtonGroup.group: button_group
            icon.source: "qrc:/svg/addresses.svg"
            ToolTip.text: qsTrId('id_addresses')
            enabled: !account_view.account.wallet.watchOnly
            onClicked: checked = true
        }
        TabButton {
            ButtonGroup.group: button_group
            icon.source: "qrc:/svg/coins.svg"
            ToolTip.text: qsTrId('Coins')
            enabled: !account_view.account.wallet.watchOnly
            onClicked: checked = true
        }
        HSpacer {
        }
        GButton {
            id: send_button
            Layout.alignment: Qt.AlignRight
            large: true
            enabled: !account_view.account.wallet.watchOnly && !wallet.locked && account.balance > 0
            hoverEnabled: true
            text: qsTrId('id_send')
            onClicked: send_dialog.createObject(window, { account: account_view.account }).open()
            ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
            ToolTip.text: qsTrId('id_insufficient_lbtc_to_send_a')
            ToolTip.visible: hovered && !enabled
        }
        GButton {
            Layout.alignment: Qt.AlignRight
            large: true
            enabled: !wallet.locked
            text: qsTrId('id_receive')
            onClicked: receive_dialog.createObject(window, { account: account_view.account }).open()
        }
    }

    StackLayout {
        id: stack_layout
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.bottomMargin: constants.p1
        currentIndex: account_view.account.wallet.network.liquid ? 0 : 2

        OverviewView {
            id: overview_view
            showAllAssets: false
        }

        AssetListView {
            account: account_view.account
        }

        TransactionListView {
            account: account_view.account
        }

        Loader {
            active: !account_view.account.wallet.watchOnly
            sourceComponent: AddressesListView {
                id: addresses_view
                account: account_view.account
            }
        }

        Loader {
            active: !account_view.account.wallet.watchOnly
                sourceComponent: OutputsListView {
                id: outputs_view
                account: account_view.account
            }
        }
    }
    Component {
        id: send_dialog
        SendDialog { }
    }

    Component {
        id: receive_dialog
        ReceiveDialog { }
    }

    component TabButton: ToolButton {
        icon.width: constants.p4
        icon.height: constants.p4
        icon.color: Qt.rgba(1, 1, 1, enabled ? 1 : 0.5)
        padding: 4
        background: Rectangle {
            color: parent.checked ? constants.c400 : parent.hovered ? constants.c600 : constants.c700
            radius: 4
        }
        ToolTip.delay: 300
        ToolTip.visible: hovered
    }
}
