import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3

Pane {
    property bool showAllAssets: false
    required property Account account

    id: self
    Layout.fillWidth: true
    Layout.fillHeight: true
    background: null
    padding: 0
    contentItem: ColumnLayout {
        Layout.fillWidth: true
        spacing: constants.p1

        RowLayout {
            Layout.preferredHeight: constants.p5

            Label {
                text: "Overview"
                font.pixelSize: 22
                font.styleName: "Bold"
                verticalAlignment: Label.AlignVCenter
            }

            HSpacer { }
        }

        LiquidHeader {
            Layout.topMargin: constants.p2
            visible: self.account.wallet.network.liquid
        }

        TransactionListView {
            id: transaction_list_view
            interactive: false
            hasExport: false
            label.font.pixelSize: 18
            Layout.fillWidth: true
            Layout.fillHeight: true
            height: contentHeight
            account: self.account
        }
    }

    component LiquidHeader: ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: constants.p1

        AccountIdBadge {
            visible: self.account.json.type === '2of2_no_recovery'
            account: self.account
            Layout.fillWidth: true
        }

        AssetListView {
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

        GButton {
            visible: false
            enabled: self.account.balances.length > 3
            text: {
                const count = self.account.balances.length
                if (count <= 3) return qsTrId('id_no_more_assets')
                if (self.showAllAssets) return qsTrId('id_hide_assets')
                return qsTrId('id_show_all_assets')
            }
            Layout.alignment: Qt.AlignCenter
            onClicked: self.showAllAssets = !self.showAllAssets
        }
    }
}
