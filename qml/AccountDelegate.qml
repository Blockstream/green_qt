import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

Button {
    required property Account account
    required property int index

    id: delegate
    focusPolicy: Qt.ClickFocus
    onClicked: {
        delegate.ListView.view.currentIndex = index
    }
    Menu {
        id: account_delegate_menu
        MenuItem {
            text: qsTrId('id_rename')
            onTriggered: {
                delegate.ListView.view.currentIndex = index
                name_field.forceActiveFocus()
            }
        }
        MenuItem {
            text: qsTrId('id_unarchive')
            onTriggered: delegate.account.show()
            visible: delegate.account.hidden
            height: visible ? implicitHeight : 0
        }
        MenuItem {
            text: qsTrId('id_archive')
            enabled: account_list_view.count > 1
            onTriggered: delegate.account.hide()
            visible: !delegate.account.hidden
            height: visible ? implicitHeight : 0
        }
    }
    background: Rectangle {
        color: delegate.highlighted ? constants.c700 : delegate.hovered ? constants.c700 : constants.c800
        radius: 4
        border.width: 1
        border.color: delegate.highlighted ? constants.g500 : constants.c700
        TapHandler {
            enabled: delegate.highlighted
            acceptedButtons: Qt.RightButton
            onTapped: account_delegate_menu.popup()
        }
    }
    highlighted: currentAccount === delegate.account
    leftPadding: constants.p2
    rightPadding: constants.p2
    topPadding: constants.p2
    bottomPadding: constants.p2
    hoverEnabled: true
    width: ListView.view.contentWidth
    contentItem: ColumnLayout {
        spacing: 8
        RowLayout {
            spacing: 0
            EditableLabel {
                id: name_field
                Layout.fillWidth: true
                font.styleName: 'Medium'
                font.pixelSize: 14
                leftInset: -8
                rightInset: -8
                text: UtilJS.accountName(account)
                enabled: !account.wallet.watchOnly && delegate.ListView.isCurrentItem && !delegate.account.wallet.locked
                onEdited: {
                    if (enabled) {
                        if (delegate.account.rename(text, activeFocus)) {
                            Analytics.recordEvent('account_rename', AnalyticsJS.segmentationSubAccount(delegate.account))
                        }
                    }
                }
            }
            Item {
                implicitWidth: constants.s1
            }
            AccountTypeBadge {
                account: delegate.account
            }
            Item {
                implicitWidth: delegate.hovered || account_delegate_menu.opened ? constants.s1 + tool_button.width : 0
                Behavior on implicitWidth {
                    SmoothedAnimation {}
                }
                implicitHeight: tool_button.height
                clip: true
                GToolButton {
                    id: tool_button
                    x: constants.s1
                    icon.source: 'qrc:/svg/kebab.svg'
                    onClicked: account_delegate_menu.popup()
                }
            }
        }
        RowLayout {
            visible: asset_icon_repeater.model.lenght > 0
            spacing: 2
            Repeater {
                id: asset_icon_repeater
                model: {
                    const assets = []
                    let without_icon = false
                    for (let i = 0; i < account.balances.length; i++) {
                        const { amount, asset }= account.balances[i]
                        if (amount === 0) continue;
                        if (asset.icon || !without_icon) assets.push(asset)
                        without_icon = !asset.icon
                    }
                    return assets
                }
                AssetIcon {
                    asset: modelData
                    size: 16
                }
            }
            HSpacer {
            }
        }
        RowLayout {
            HSpacer {
            }
            CopyableLabel {
                text: formatAmount(account.balance)
                font.pixelSize: 14
                font.styleName: 'Regular'
            }
            Label {
                text: '≈'
                font.pixelSize: 14
                font.styleName: 'Regular'
            }
            CopyableLabel {
                text: formatFiat(account.balance)
                font.pixelSize: 14
                font.styleName: 'Regular'
            }
        }
    }
}
