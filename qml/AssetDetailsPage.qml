import Blockstream.Green
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    signal accountClicked(Account account)
    required property Context context
    required property Asset asset
    property Account account
    readonly property string ticker: {
        if (!self.asset) return
        return self.asset.data.ticker ?? ''
    }

    id: self
    title: qsTrId('id_asset_details')
    rightItem: RowLayout {
        spacing: 20
        ShareButton {
            url: self.asset.url
            visible: self.asset.hasData
        }
        CloseButton {
            onClicked: self.closeClicked()
        }
    }
    contentItem: VFlickable {
        alignment: Qt.AlignTop
        spacing: 5
        AssetIcon {
            Layout.alignment: Qt.AlignCenter
            Layout.bottomMargin: 10
            asset: self.asset
            size: 48
        }
        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            font.pixelSize: 18
            font.weight: 600
            horizontalAlignment: Label.AlignHCenter
            text: self.asset.name
            wrapMode: Label.Wrap
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            text: self.asset.data.entity?.domain ?? ''
            opacity: 0.6
            visible: self.asset.data.entity ?? false
        }
        Label {
            color: '#A0A0A0'
            font.pixelSize: 16
            font.weight: 400
            text: qsTrId('id_accounts')
        }
        Repeater {
            model: {
                const accounts = []
                for (let i = 0; i < self.context.accounts.length; i++) {
                    const account =  self.context.accounts[i]
                    const satoshi = account.json.satoshi[self.asset.id]
                    if (satoshi) {
                        accounts.push({ account, satoshi: String(satoshi) })
                    }
                }
                return accounts.sort((a, b) => {
                    const as = Number(a.satoshi)
                    const bs = Number(b.satoshi)
                    if (as > bs) return -1
                    if (as < bs) return 1
                    return a.account.name.localeCompare(b.account.name)
                })
            }
            delegate: AccountButton {
                required property var modelData
                id: button
                account: button.modelData.account
                satoshi: button.modelData.satoshi
            }
        }
        Rectangle {
            Layout.bottomMargin: 20
            Layout.topMargin: 20
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: '#313131'
            visible: details_grid.visible
        }
        GridLayout {
            id: details_grid
            columns: 2
            visible: self.asset.id !== 'btc'
            Label {
                Layout.minimumWidth: 100
                color: '#929292'
                font.pixelSize: 12
                font.weight: 400
                text: qsTrId('id_ticker')
                visible: self.ticker ?? false
            }
            Label {
                Layout.fillWidth: true
                color: '#FFF'
                font.pixelSize: 12
                font.weight: 400
                text: self.ticker ?? ''
                visible: self.ticker ?? false
            }
            Label {
                color: '#929292'
                font.pixelSize: 12
                font.weight: 400
                text: qsTrId('id_precision')
                visible: self.asset.data.precision >= 0 ?? false
            }
            Label {
                Layout.fillWidth: true
                color: '#FFF'
                font.pixelSize: 12
                font.weight: 400
                text: self.asset.data.precision ?? ''
                visible: self.asset.data.precision >= 0 ?? false
            }
            Label {
                Layout.alignment: Qt.AlignTop
                color: '#929292'
                font.pixelSize: 12
                font.weight: 400
                text: qsTrId('id_asset_id')
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                color: '#FFF'
                font.pixelSize: 12
                font.weight: 400
                text: self.asset.id
                wrapMode: Label.Wrap
            }
        }
        Rectangle {
            Layout.bottomMargin: 20
            Layout.topMargin: 20
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: '#313131'
        }
        VSpacer {
        }
    }

    component AccountButton: AbstractButton {
        required property Account account
        required property string satoshi
        Convert {
            id: convert
            account: button.account
            asset: self.asset
            input: ({ satoshi: button.satoshi })
            unit: button.account.session.unit
        }
        Layout.fillWidth: true
        onClicked: self.accountClicked(button.account)
        id: button
        enabled: button.account != self.account
        padding: 20
        background: Rectangle {
            color: Qt.lighter('#181818', button.account == self.account ? 1.4 : button.hovered ? 1.1 : 1)
            radius: 5
            border.color: '#262626'
            border.width: 1
        }
        contentItem: RowLayout {
            spacing: 20
            ColumnLayout {
                Label {
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: true
                    color: '#FFF'
                    font.pixelSize: 14
                    font.weight: 500
                    text: UtilJS.accountName(button.account)
                }
                Label {
                    font.pixelSize: 12
                    font.weight: 400
                    font.capitalization: Font.AllUppercase
                    color: '#929292'
                    text: UtilJS.networkLabel(button.account.network) + ' / ' + UtilJS.accountLabel(button.account)
                    elide: Label.ElideLeft
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                }
            }
            ColumnLayout {
                Label {
                    Layout.alignment: Qt.AlignRight
                    color: '#FFF'
                    font.pixelSize: 14
                    font.weight: 500
                    text: convert.output.label
                }
                Label {
                    Layout.alignment: Qt.AlignRight
                    color: '#929292'
                    font.pixelSize: 12
                    font.weight: 400
                    text: convert.fiat.label
                    visible: convert.fiat.available
                }
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/right.svg'
                opacity: button.enabled ? 1 : 0
            }
        }
    }
}
