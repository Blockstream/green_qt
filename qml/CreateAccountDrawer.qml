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
                    font.family: 'SF Compact Display'
                    font.pixelSize: 14
                    font.weight: 500
                    opacity: 0.4
                    text: 'Security Policy'
                }
                SecurityPolicyButton {
                    icon.source: 'qrc:/svg/singleSig.svg'
                    type: 'SINGLESIG / LEGACY SEGWIT'
                    title: 'Standard'
                    description: 'Simple, portable, standard account, secured by your key, the recovery phrase.'
                }
                SecurityPolicyButton {
                    icon.source: 'qrc:/svg/multi-sig.svg'
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

    component SecurityPolicyButton: AbstractButton {
        required property string title
        required property string type
        required property string description

        Layout.fillWidth: true
        id: self
        padding: 20
        background: Rectangle {
            color: '#222226'
            radius: 5
            Rectangle {
                border.width: 2
                border.color: '#00B45A'
                color: 'transparent'
                radius: 9
                anchors.fill: parent
                anchors.margins: -4
                opacity: self.visualFocus ? 1 : 0
            }
        }
        contentItem: RowLayout {
            spacing: 10
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                RowLayout {
                    spacing: 4
                    opacity: 0.6
                    Image {
                        source: self.icon.source
                        Layout.preferredHeight: 16
                        Layout.preferredWidth: 16
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignCenter
                        font.family: 'SF Compact Display'
                        font.pixelSize: 10
                        font.weight: 400
                        text: self.type
                    }
                }
                Label {
                    font.family: 'SF Compact Display'
                    font.pixelSize: 16
                    font.weight: 600
                    text: self.title
                }
                Item {
                    Layout.minimumHeight: 10
                }
                Label {
                    Layout.fillWidth: true
                    font.family: 'SF Compact Display'
                    font.pixelSize: 12
                    font.weight: 400
                    opacity: 0.6
                    text: self.description
                    wrapMode: Label.WordWrap
                }
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                sourceSize.height: 32
                sourceSize.width: 32
                source: 'qrc:/svg/arrow_right.svg'
            }
        }
    }
}
