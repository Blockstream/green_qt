import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    signal accountClicked(account: Account)
    required property Context context
    required property Asset asset
    required property string message
    required property list<Account> accounts
    objectName: "AccountSelectorPage"
    id: self
    title: qsTrId('id_select_account')
    contentItem: VFlickable {
        alignment: Qt.AlignTop
        spacing: 5
        Label {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 0
            Layout.margins: 24
            horizontalAlignment: Label.AlignHCenter
            color: '#A0A0A0'
            text: self.message
            visible: self.message?.length > 0
            wrapMode: Label.Wrap
        }
        Pane {
            Layout.fillWidth: true
            padding: 10
            visible: self.asset.amp
            background: Rectangle {
                color: '#00BCFF'
                opacity: 0.2
            }
            contentItem: RowLayout {
                spacing: 10
                Image {
                    Layout.alignment: Qt.AlignCenter
                    source: 'qrc:/svg2/shield_warning.svg'
                }
                Label {
                    Layout.preferredWidth: 0
                    Layout.fillWidth: true
                    color: '#00BCFF'
                    font.pixelSize: 12
                    font.weight: 600
                    text: `${self.asset.name} is an AMP asset. You need an AMP account in order to receive it.`
                    wrapMode: Label.WordWrap
                }
            }
        }
        Repeater {
            id: accounts_repeater
            model: self.accounts
            delegate: SelectAccountButton {
                required property var modelData
                Layout.fillWidth: true
                id: button
                account: button.modelData
                onClicked: self.accountClicked(button.account)
            }
        }
        VSpacer {
        }
    }

    component SelectAccountButton: AbstractButton {
        required property Account account
        readonly property string satoshi: button.account.json.satoshi[self.asset.id] ?? '0'
        id: button
        background: Rectangle {
            border.color: '#262626'
            border.width: 1
            color: Qt.lighter('#181818', button.enabled && button.hovered ? 1.2 : 1)
            radius: 8
        }
        padding: 20
        contentItem: RowLayout {
            spacing: 8
            ColumnLayout {
                Label {
                    Layout.fillWidth: true
                    font.pixelSize: 14
                    font.weight: 500
                    text: UtilJS.accountName(button.account)
                    wrapMode: Label.Wrap
                }
                Label {
                    font.pixelSize: 11
                    font.weight: 400
                    opacity: 0.4
                    text: UtilJS.networkLabel(button.account.network) + ' / ' + UtilJS.accountLabel(button.account)
                }
            }
            Convert {
                id: convert
                account: button.account
                asset: self.asset
                input: ({ satoshi: button.satoshi })
                unit: UtilJS.unit(button.account)
            }
            ColumnLayout {
                Label {
                    Layout.alignment: Qt.AlignRight
                    font.pixelSize: 14
                    font.weight: 500
                    text: convert.output.label
                    wrapMode: Label.Wrap
                }
                Label {
                    Layout.alignment: Qt.AlignRight
                    font.pixelSize: 11
                    font.weight: 400
                    opacity: 0.4
                    text: convert.fiat.label
                    visible: convert.fiat.available
                }
            }
            RightArrowIndicator {
                active: button.hovered
            }
        }
    }
}
