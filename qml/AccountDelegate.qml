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

    id: delegate
    focusPolicy: Qt.ClickFocus
    onClicked: {
        delegate.ListView.view.currentIndex = index
    }
    background: Rectangle {
        color: UtilJS.networkColor(delegate.account.network)
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
            Image {
                fillMode: Image.PreserveAspectFit
                sourceSize.height: 16
                sourceSize.width: 16
                source: delegate.account.network.electrum ? 'qrc:/svg/key.svg' : 'qrc:/svg/multi-sig.svg'
            }
            Label {
                font.pixelSize: 10
                font.weight: 400
                font.styleName: 'Regular'
                font.capitalization: Font.AllUppercase
                color: 'white'
                text: UtilJS.networkLabel(delegate.account.network) + ' / ' + UtilJS.accountLabel(delegate.account)
                elide: Label.ElideLeft
                Layout.fillWidth: true
                Layout.preferredWidth: 0
            }
            RowLayout {
                Layout.fillWidth: false
                Layout.alignment: Qt.AlignBottom
                spacing: -12
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
        Item {
            Layout.fillWidth: true
            implicitHeight: card_footer.height
            RowLayout {
                id: card_footer
                width: parent.width
                ColumnLayout {
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
                ToolButton {
                    id: tool_button
                    Layout.alignment: Qt.AlignBottom
                    visible: delegate.highlighted
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
                    onClicked: account_delegate_menu.open()
                    GMenu {
                        id: account_delegate_menu
                        x: tool_button.width + 8
                        y: (tool_button.height - account_delegate_menu.height) * 0.5
                        pointerX: 0
                        pointerY: 0.5
                        enabled: !delegate.account.context.watchonly
                        GMenu.Item {
                            text: qsTrId('id_rename')
                            icon.source: 'qrc:/svg/wallet-rename.svg'
                            onClicked: {
                                account_delegate_menu.close()
                                delegate.ListView.view.currentIndex = index
                                name_field.forceActiveFocus()
                            }
                        }
                        GMenu.Item {
                            text: qsTrId('id_unarchive')
                            icon.source: 'qrc:/svg/unarchive.svg'
                            onClicked: {
                                account_delegate_menu.close()
                                controller.setAccountHidden(delegate.account, false)
                            }
                            visible: delegate.account.hidden
                            height: visible ? implicitHeight : 0
                        }
                        GMenu.Item {
                            text: qsTrId('id_archive')
                            enabled: account_list_view.count > 1
                            icon.source: 'qrc:/svg/archived.svg'
                            onClicked: {
                                account_delegate_menu.close()
                                controller.setAccountHidden(delegate.account, true)
                            }
                            visible: !delegate.account.hidden
                            height: visible ? implicitHeight : 0
                        }
                    }
                }
            }
        }
    }
}
