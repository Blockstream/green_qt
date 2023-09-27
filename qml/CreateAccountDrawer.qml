import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

WalletDrawer {
    id: self
    width: 450

    CreateAccountController {
        id: controller
        context: self.context
        asset: AssetManager.assetWithId('bitcoin')
    }

    contentItem: StackView {
        id: stack_view
        focus: true
        initialItem: Page {
            background: null
            header: Pane {
                background: null
                padding: 0
                bottomPadding: 20
                contentItem: RowLayout {
                    DrawerTitle {
                        text: 'Create New Account'
                    }
                    HSpacer {
                    }
                    CloseButton {
                        onClicked: self.close()
                    }
                }
            }
            contentItem: ColumnLayout {
                spacing: 10
                FieldTitle {
                    text: 'Asset'
                }
                AssetField {
                    Layout.fillWidth: true
                    asset: controller.asset
                    focus: true
                    onClicked: stack_view.push(asset_selector)
                }
                FieldTitle {
                    Layout.topMargin: 15
                    text: 'Security Policy'
                }
                SecurityPolicyButton {
                    Layout.fillWidth: true
                    icon.source: 'qrc:/svg2/singlesig.svg'
                    type: 'SINGLESIG / LEGACY SEGWIT'
                    title: 'Standard'
                    description: 'Simple, portable, standard account, secured by your key, the recovery phrase.'
                }
                SecurityPolicyButton {
                    Layout.fillWidth: true
                    icon.source: 'qrc:/svg2/multisig.svg'
                    type: 'MULTISIG / 2OF2'
                    title: '2FA Protected '
                    description: 'Quick setup 2FA account, ideal for active spenders (2FA expires if you don\'t move funds every 6 months).'
                }
                VSpacer {
                }
                Label {
                    Layout.alignment: Qt.AlignCenter
                    color: '#00B45A'
                    font.family: 'SF Compact Display'
                    font.pixelSize: 14
                    font.weight: 500
                    text: 'See Advanced Options'
                }
            }
        }
    }

    Component {
        id: asset_selector
        AssetSelector {
            asset: controller.asset
            onCanceled: stack_view.pop()
            onSelected: (asset) => {
                controller.asset = asset
                stack_view.pop()
            }
        }
    }
}
