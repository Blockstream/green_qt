import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

ItemDelegate {
    required property Account account
    required property int index

    function networkColor (network) {
        if (network.mainnet) {
            if (network.liquid) {
                return '#46BEAE'
            } else {
                return '#FF8E00'
            }
        } else if (network.localtest) {
            if (network.liquid) {
                return '#46BEAE'
            } else {
                return '#FF8E00'
            }
        } else {
            if (network.liquid) {
                return '#8C8C8C'
            } else {
                return '#8C8C8C'
            }
        }
    }

    id: delegate
    focusPolicy: Qt.ClickFocus
    onClicked: {
        delegate.ListView.view.currentIndex = index
    }
    Menu {
        id: account_delegate_menu
        enabled: !delegate.account.context.watchonly
        MenuItem {
            text: qsTrId('id_rename')
            onTriggered: {
                delegate.ListView.view.currentIndex = index
                name_field.forceActiveFocus()
            }
        }
        MenuItem {
            text: qsTrId('id_unarchive')
            onTriggered: controller.setAccountHidden(delegate.account, false)
            visible: delegate.account.hidden
            height: visible ? implicitHeight : 0
        }
        MenuItem {
            text: qsTrId('id_archive')
            enabled: account_list_view.count > 1
            onTriggered: controller.setAccountHidden(delegate.account, true)
            visible: !delegate.account.hidden
            height: visible ? implicitHeight : 0
        }
    }
    background: Rectangle {
        color: networkColor(delegate.account.network)
        radius: 5
        opacity: delegate.highlighted ? 0.8 : 0.3
        Behavior on opacity {
            OpacityAnimator {
            }
        }
    }
    highlighted: currentAccount === delegate.account
    leftPadding: constants.p2
    rightPadding: constants.p2
    topPadding: constants.p1
    bottomPadding: constants.p1
    hoverEnabled: true
    width: ListView.view.contentWidth
    contentItem: ColumnLayout {
        spacing: 6
        RowLayout {
            AccountTypeBadge {
                account: delegate.account
            }
            HSpacer {
            }
            ToolButton {
                Layout.alignment: Qt.AlignBottom
                visible: !delegate.account.hidden
                icon.source: 'qrc:/svg/3-dots.svg'
                leftPadding: 0
                rightPadding: 0
                bottomPadding: 0
                topPadding: 0
                leftInset: 0
                rightInset: 0
                topInset: 0
                bottomInset: 0
                background: null
                onClicked: account_delegate_menu.popup()
            }
            AccountArchivedBadge {
                account: delegate.account
            }
        }
        EditableLabel {
            id: name_field
            Layout.fillWidth: true
            font.styleName: 'Medium'
            font.pixelSize: 16
            topPadding: 0
            leftInset: -8
            topInset: -4
            rightInset: -8
            bottomInset: -4
            text: UtilJS.accountName(account)
            enabled: !account.context.watchonly && delegate.ListView.isCurrentItem && !delegate.account.context.locked
            onEdited: (text) => {
                if (enabled) {
                    if (controller.setAccountName(delegate.account, text, activeFocus)) {
                        Analytics.recordEvent('account_rename', AnalyticsJS.segmentationSubAccount(delegate.account))
                    }
                }
            }
        }
        Item {
            Layout.minimumHeight: 16
        }
        RowLayout {
            ColumnLayout {
                Layout.fillWidth: false
                CopyableLabel {
                    text: formatFiat(account.balance)
                    font.pixelSize: 10
                    font.weight: 400
                    font.styleName: 'Regular'
                }
                CopyableLabel {
                    text: formatAmount(account.balance)
                    font.pixelSize: 14
                    font.weight: 600
                    font.styleName: 'Medium'
                }
            }
            HSpacer {
            }
            RowLayout {
                Layout.fillWidth: false
                Layout.alignment: Qt.AlignBottom
                spacing: delegate.hovered ? 4 : -12
                Behavior on spacing {
                    SmoothedAnimation {
                    }
                }
                Repeater {
                    id: asset_icon_repeater
                    model: {
                        const assets = []
                        let without_icon = false
                        for (let i = 0; i < delegate.account.balances.length; i++) {
                            const balance = delegate.account.balances[i]
                            if (balance.amount === 0) continue;
                            const asset = balance.asset
                            if (asset.icon) {
                                assets.push(asset)
                            } else if (!without_icon) {
                                assets.unshift(asset)
                                without_icon = true
                            }
                        }
                        return assets
                    }
                    AssetIcon {
                        asset: modelData
                        size: 24
                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: 'transparent'
                            border.width: 1
                            border.color: 'white'
                        }
                    }
                }
            }
        }
    }
}
