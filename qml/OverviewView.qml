import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

GPane {
    required property Context context
    required property Account account

    id: self
    Layout.fillWidth: true
    Layout.fillHeight: true

    contentItem: ColumnLayout {
        spacing: constants.p3

        LiquidHeader {
            visible: self.account.network.liquid
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            Label {
                text: qsTrId('id_latest_transactions')
                font.pixelSize: 16
                font.styleName: 'Bold'
            }
            Repeater {
                model: LimitProxyModel {
                    source: transaction_list_model
                    limit: 5
                }
                delegate: TransactionDelegate {
                    Layout.fillWidth: true
                    context: self.context
                    account: self.account
                }
            }
            GButton {
                Layout.alignment: Qt.AlignHCenter
                text: qsTrId('id_show_all')
                onClicked: navigation.set({ view: 'transactions' })
            }
        }
        VSpacer {
        }
    }

    component LiquidHeader: ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: false
        spacing: constants.p1

        AccountIdBadge {
            visible: self.account.type === '2of2_no_recovery'
            account: self.account
            Layout.fillWidth: true
        }

        ColumnLayout {
            spacing: 8
            Label {
                text: qsTrId('id_assets')
                font.pixelSize: 16
                font.styleName: 'Bold'
            }
            Repeater {
                id: asset_repeater
                delegate: AssetDelegate {
                    Layout.fillWidth: true
                    balance: modelData
                    onClicked: if (hasDetails) balance_dialog.createObject(window, { balance }).open()
                }
                model: {
                    const balances = []
                    for (let i = 0; i < self.account.balances.length; ++i) {
                        if (i === 3) break
                        balances.push(self.account.balances[i])
                    }
                    return balances
                }
            }
            GButton {
                visible: self.account.balances.length > 3
                Layout.alignment: Qt.AlignHCenter
                text: qsTrId('id_show_all')
                onClicked: navigation.set({ view: 'assets' })
            }
        }
    }
}
