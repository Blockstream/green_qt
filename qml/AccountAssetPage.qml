import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

StackViewPage {
    required property Context context
    required property Asset asset
    required property Account account
    Controller {
        id: controller
        context: account.context
    }
    objectName: "AccountAssetPage"
    id: self
    title: UtilJS.accountName(self.account)
    centerItem: EditableLabel {
        id: name_field
        color: '#FFFFFF'
        readOnly: self.context.watchonly
        font.pixelSize: 14
        font.weight: 600
        text: UtilJS.accountName(self.account)
        onEditingFinished: {
            if (name_field.enabled) {
                if (controller.setAccountName(self.account, name_field.text)) {
                    Analytics.recordEvent('account_rename', AnalyticsJS.segmentationSubAccount(Settings, self.account))
                }
            }
            name_field.nextItemInFocusChain().forceActiveFocus()
        }
    }
    rightItem: RowLayout {
        spacing: 20
        CircleButton {
            Layout.alignment: Qt.AlignBottom
            id: tool_button
            hoverEnabled: !options_menu.visible
            icon.source: 'qrc:/svg/3-dots.svg'
            onClicked: options_menu.visible ? options_menu.close() : options_menu.open()
            GMenu {
                id: options_menu
                x: 1.5 * tool_button.width - options_menu.width
                y: tool_button.height + 8
                pointerX: 1
                pointerXOffset: - tool_button.width
                pointerY: 0
                enabled: !self.context.watchonly
                spacing: 0
                GMenu.Item {
                    enabled: !self.context.watchonly
                    icon.source: 'qrc:/svg/wallet-rename.svg'
                    text: qsTrId('id_rename')
                    onClicked: {
                        options_menu.close()
                        name_field.forceActiveFocus()
                    }
                }
                GMenu.Item {
                    icon.source: 'qrc:/svg2/copy.svg'
                    text: qsTrId('id_copy') + ' ' + qsTrId('id_amp_id')
                    visible: self.account.type === '2of2_no_recovery'
                    onClicked: {
                        options_menu.close()
                        Clipboard.copy(self.account.json.receiving_id)
                    }
                }
            }
        }
        CloseButton {
            onClicked: self.closeClicked()
        }
    }
    bottomPadding: 0
    footer: null
    contentItem: TListView {
        id: list_view
        spacing: 8
        header: ColumnLayout {
            onHeightChanged: list_view.contentY = -(list_view.headerItem?.height ?? 0)
            width: list_view.width
            spacing: 0
            AssetIcon {
                Layout.alignment: Qt.AlignCenter
                asset: self.asset
                size: 48
            }
            Convert {
                id: convert
                account: self.account
                asset: self.asset
                input: ({ satoshi: self.account.json.satoshi[self.asset.id] })
                unit: UtilJS.unit(self.context)
            }
            Label {
                Layout.topMargin: 12
                Layout.alignment: Qt.AlignCenter
                color: '#FAFAFA'
                font.pixelSize: 24
                font.weight: 500
                text: convert.output.label
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                color: '#A0A0A0'
                font.pixelSize: 14
                font.weight: 400
                text: convert.fiat.label
                visible: convert.fiat.available
            }
            RowLayout {
                Layout.bottomMargin: 12
                Layout.topMargin: 12
                spacing: 8
                visible: !self.account.hidden
                ActionButton {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    enabled: !self.account.network.liquid && self.asset.key === 'btc'
                    icon.source: 'qrc:/fafafa/20/coin-vertical.svg'
                    text: 'Buy'
                    onClicked: {
                        self.StackView.view.push(buy_page)
                    }
                }
                ActionButton {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    enabled: !self.context.watchonly
                    icon.source: 'qrc:/svg/send-white.svg'
                    text: qsTrId('id_send')
                    onClicked: {
                        self.StackView.view.push(send_page)
                    }
                }
                ActionButton {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    icon.source: 'qrc:/svg/receive-white.svg'
                    text: qsTrId('id_receive')
                    onClicked: {
                        self.StackView.view.push(receive_page)
                    }
                }
            }
            FieldTitle {
                Layout.bottomMargin: 12
                text: qsTrId('id_transactions')
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                color: '#929292'
                font.pixelSize: 14
                text: `You don't have any transactions yet.`
                visible: list_view.count === 0
                wrapMode: Label.Wrap
            }
        }
        model: TransactionModel {
            id: model
            context: self.context
            Component.onCompleted: {
                model.updateFilterAccounts(self.account, true)
                model.updateFilterAssets(self.asset, true)
            }
        }
        delegate: HomePage.TransactionDelegate2 {
            id: delegate
            onClicked: {
                self.StackView.view.push(transaction_details_page, { transaction: delegate.transaction })
            }
        }
        footer: Item {
            implicitHeight: 0
        }
        MouseArea {
            anchors.fill: parent
            enabled: name_field.activeFocus
            onClicked: list_view.forceActiveFocus()
        }
    }

    component ActionButton: PushButton {
        id: button
        fillColor: '#181818'
        borderColor: '#262626'
        leftPadding: 20
        rightPadding: 20
        topPadding: 20
        bottomPadding: 20
        contentItem: ColumnLayout {
            spacing: 10
            Image {
                Layout.alignment: Qt.AlignCenter
                id: image
                source: button.icon.source
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                font.pixelSize: 14
                font.weight: 400
                color: '#FAFAFA'
                text: button.text
            }
        }
    }

    Component {
        id: buy_page
        BuyPage {
            context: self.context
            account: self.account
            onCloseClicked: self.close()
            onShowTransactions: self.close()
        }
    }

    Component {
        id: receive_page
        ReceivePage {
            context: self.context
            account: self.account
            asset: self.asset
            readonly: true
            onCloseClicked: self.closeClicked()
        }
    }

    Component {
        id: send_page
        SendPage {
            context: self.context
            account: self.account
            asset: self.asset
            readonly: true
            onCloseClicked: self.closeClicked()
        }
    }

    Component {
        id: transaction_details_page
        TransactionView {
            onCloseClicked: self.closeClicked()
        }
    }
}
