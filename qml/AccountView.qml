import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.14
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

StackView {
    id: account_view
    required property Account account
    initialItem: Page {
        background: Item {}
        header: RowLayout {
            TabBar {
                id: tab_bar
                leftPadding: 16
                background: Item {}
                TabButton {
                    text: qsTrId('id_transactions')
                    width: 160
                }

                TabButton {
                    visible: account.wallet.network.liquid
                    text: qsTrId('id_assets')
                    width: 160
                }
            }
        }
        contentItem: StackLayout {
            id: stack_layout
            currentIndex: tab_bar.currentIndex
            TransactionListView {
                account: account_view.account
                onClicked: account_view.push(transaction_view_component, { transaction })
            }
            Loader {
                active: account.wallet.network.liquid
                sourceComponent: AssetListView {
                    account: account_view.account
                    onClicked: account_view.push(asset_view_component, { balance })
                }
            }
        }
    }
    Component {
        id: transaction_view_component
        TransactionView { }
    }
    Component {
        id: asset_view_component
        AssetView { }
    }
}
