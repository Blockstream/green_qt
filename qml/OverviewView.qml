import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3

GPane {
    property bool showAllAssets: false
    required property Account account

    id: self
    Layout.fillWidth: true
    Layout.fillHeight: true
    padding: 0
    contentItem: ColumnLayout {
        Layout.fillWidth: true
        spacing: constants.p1

        GHeader {
            Label {
                Layout.alignment: Qt.AlignVCenter
                text: qsTrId('id_overview')
                font.pixelSize: 20
                font.styleName: 'Bold'
                verticalAlignment: Label.AlignVCenter
            }
            HSpacer {
            }
        }

        LiquidHeader {
            Layout.topMargin: constants.p2
            visible: self.account.wallet.network.liquid
        }

        TransactionListView {
            id: transaction_list_view
            header: GHeader {
                Label {
                    Layout.alignment: Qt.AlignVCenter
                    id: label
                    text: qsTrId('id_latest_transactions')
                    font.pixelSize: 20
                    font.styleName: 'Bold'
                }
                HSpacer {
                }
                GButton {
                    visible: transaction_list_view.list.count > 0
                    Layout.alignment: Qt.AlignVCenter
                    text: qsTrId('id_show_all')
                    onClicked: wallet_view_header.currentView = 2
                }
            }
            hasExport: false
            label.font.pixelSize: 18
            Layout.fillWidth: true
            Layout.fillHeight: true
            height: contentHeight
            account: self.account
            maxRowCount: 10
        }
    }

    component LiquidHeader: ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: constants.p1

        AccountIdBadge {
            visible: self.account.type === '2of2_no_recovery'
            account: self.account
            Layout.fillWidth: true
        }

        AssetListView {
            account: self.account
            header: GHeader {
                Label {
                    text: qsTrId('id_assets')
                    font.pixelSize: 20
                    font.styleName: 'Bold'
                }
                HSpacer {
                }
                GButton {
                    visible: self.account.balances.length > 3
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTrId('id_show_all')
                    onClicked: wallet_view_header.currentView = 1
                }
            }
            Layout.fillWidth: true
            label.font.pixelSize: 18
            model: {
                const balances = []
                for (let i = 0; i < self.account.balances.length; ++i) {
                    if (!self.showAllAssets && i === 3) break
                    balances.push(self.account.balances[i])
                }
                return balances
            }
        }
    }
}
