import Blockstream.Green
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    signal accountClicked(Account account)
    signal transactionsClicked()
    required property Context context
    required property Asset asset
    property Account account
    property Action closeAction
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
        }
        CloseButton {
            action: self.closeAction
            visible: self.closeAction || false
        }
    }
    contentItem: Flickable {
        ScrollIndicator.vertical: ScrollIndicator {
        }
        id: flickable
        clip: true
        contentWidth: flickable.width
        contentHeight: layout.height
        ColumnLayout {
            id: layout
            width: flickable.width
            spacing: 5
            AssetIcon {
                Layout.alignment: Qt.AlignCenter
                Layout.bottomMargin: 10
                asset: self.asset
                size: 64
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
            LinkButton {
                Layout.alignment: Qt.AlignCenter
                text: 'View asset transactions'
                onClicked: self.transactionsClicked()
            }
            Rectangle {
                Layout.bottomMargin: 20
                Layout.topMargin: 20
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: '#313131'
            }
            GridLayout {
                columns: 2
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
            Label {
                color: '#929292'
                font.pixelSize: 12
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
            color: Qt.lighter('#222226', button.account == self.account ? 1.4 : button.hovered ? 1.1 : 1)
            radius: 5
        }
        contentItem: RowLayout {
            spacing: 20
            ColumnLayout {
                RowLayout {
                    Layout.bottomMargin: 6
                    Image {
                        fillMode: Image.PreserveAspectFit
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        source: button.account.network.electrum ? 'qrc:/svg2/singlesig.svg' : 'qrc:/svg2/multisig.svg'
                    }
                    Label {
                        font.pixelSize: 10
                        font.weight: 400
                        font.capitalization: Font.AllUppercase
                        color: 'white'
                        text: UtilJS.networkLabel(button.account.network) + ' / ' + UtilJS.accountLabel(button.account)
                        elide: Label.ElideLeft
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                    }
                }
                Label {
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: true
                    color: '#FFF'
                    font.pixelSize: 16
                    font.weight: 400
                    text: UtilJS.accountName(button.account)
                }
            }
            ColumnLayout {
                Label {
                    Layout.alignment: Qt.AlignRight
                    color: '#FFF'
                    font.pixelSize: 14
                    font.weight: 600
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
