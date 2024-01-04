import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

ItemDelegate {
    signal accountClicked(Account account)
    signal accountArchived(Account account)
    required property Account account
    required property int index
    onClicked: delegate.accountClicked(delegate.account)
    id: delegate
    focusPolicy: Qt.ClickFocus
    background: Rectangle {
        color: UtilJS.networkColor(delegate.account.network)
        clip: true
        radius: 5
        Image {
            opacity: delegate.account.network.liquid ? 0.2 : 0.1
            source: delegate.account.network.liquid ? 'qrc:/svg2/watermark_liquid.svg' : 'qrc:/svg2/watermark_bitcoin.svg'
            anchors.right: parent.right
            anchors.top: parent.top
        }
    }
    highlighted: delegate.ListView.view.currentIndex === delegate.index
    leftPadding: constants.p2
    rightPadding: constants.p2
    topPadding: constants.p1
    bottomPadding: constants.p1
    hoverEnabled: true
    layer.enabled: true
    opacity: delegate.highlighted ? 1 : delegate.hovered ? 0.9 : 0.5
    Behavior on opacity {
        SmoothedAnimation {
            velocity: 1
        }
    }
    width: ListView.view.width
    contentItem: ColumnLayout {
        spacing: 0
        RowLayout {
            Layout.bottomMargin: 6
            Image {
                fillMode: Image.PreserveAspectFit
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                source: delegate.account.network.electrum ? 'qrc:/svg2/singlesig.svg' : 'qrc:/svg2/multisig.svg'
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
                id: assets
                Layout.fillWidth: false
                Layout.alignment: Qt.AlignBottom
                spacing: -8
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
            leftPadding: 0
            rightPadding: 0
            text: UtilJS.accountName(account)
            enabled: !delegate.account.hidden && !account.context.watchonly && delegate.ListView.isCurrentItem && !delegate.account.context.locked
            onEdited: (text) => {
                if (enabled) {
                    if (controller.setAccountName(delegate.account, text, activeFocus)) {
                        Analytics.recordEvent('account_rename', AnalyticsJS.segmentationSubAccount(delegate.account))
                    }
                }
            }
        }
        Collapsible {
            Layout.fillWidth: true
            Layout.minimumHeight: 1
            collapsed: !delegate.highlighted
            contentWidth: width
            contentHeight: details.height
            ColumnLayout {
                id: details
                width: parent.width
                Item {
                    Layout.fillWidth: true
                    Layout.topMargin: 64
                    implicitHeight: card_footer.height
                    RowLayout {
                        id: card_footer
                        width: parent.width
                        Convert {
                            id: convert
                            unit: 'sats'
                            account: delegate.account
                            value: {
                                const account = delegate.account
                                const satoshi = account.json.satoshi
                                return satoshi ? satoshi[account.network.policyAsset] : '0'
                            }
                        }
                        ColumnLayout {
                            Label {
                                text: UtilJS.incognitoFiat(delegate.account, convert.fiatLabel)
                                font.pixelSize: 10
                                font.weight: 400
                                font.styleName: 'Regular'
                            }
                            Label {
                                text: UtilJS.incognitoAmount(delegate.account, convert.unitLabel)
                                font.pixelSize: 14
                                font.weight: 600
                                font.styleName: 'Medium'
                            }
                        }
                        HSpacer {
                        }
                        ProgressIndicator {
                            Layout.alignment: Qt.AlignBottom
                            Layout.bottomMargin: 2
                            indeterminate: !delegate.account.synced
                            width: 20
                            height: 20
                        }
                        RegularButton {
                            topPadding: 4
                            bottomPadding: 4
                            font.pixelSize: 14
                            font.weight: 400
                            text: qsTrId('id_unarchive')
                            visible: delegate.highlighted && delegate.account.hidden
                            onClicked: controller.setAccountHidden(delegate.account, false)
                        }
                        CircleButton {
                            id: tool_button
                            Layout.alignment: Qt.AlignBottom
                            visible: delegate.highlighted && !delegate.account.hidden
                            icon.source: 'qrc:/svg/3-dots.svg'
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
                                    text: qsTrId('id_archive')
                                    icon.source: 'qrc:/svg/archived.svg'
                                    enabled: account_list_model.count > 1
                                    onClicked: {
                                        account_delegate_menu.close()
                                        controller.setAccountHidden(delegate.account, true)
                                        delegate.accountArchived(delegate.account)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
