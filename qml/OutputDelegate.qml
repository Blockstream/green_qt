import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

Pane {
    required property var output
    id: self
    hoverEnabled: true
    padding: constants.p3
    background: Rectangle {
        color: constants.c500
        radius: 4
    }
    spacing: constants.p2
    contentItem: RowLayout {
        spacing: constants.p2
        ColumnLayout {
            Layout.fillWidth: false
            Layout.preferredHeight: 80
            Image {
                visible: !output.account.wallet.network.liquid
                sourceSize.height: 36
                sourceSize.width: 36
                source: icons[wallet.network.id]
            }
            Loader {
                active: output.asset
                visible: active
                sourceComponent: AssetIcon {
                    asset: output.asset
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                }
            }
            VSpacer {
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: constants.p1
            Label {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: output.formatAmount()
                font.pixelSize: 16
                font.styleName: 'Medium'
            }
            Label {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: output.data["txhash"] + ':' + output.data["pt_idx"]
                font.pixelSize: 14
                font.styleName: 'Regular'
            }
            RowLayout {
                Tag {
                    visible: output.frozen
                    text: "FROZEN"
                }
                Tag {
                    text: "DUST"
                    visible: output.dust
                }
                Tag {
                    text: "NOT CONFIDENTIAL"
                    visible: !output.confidential
                }
                Tag {
                    text: output.addressType
                    font.capitalization: Font.AllUppercase
                }
                Tag {
                    text: "2FA EXPIRED"
                    visible: output.expired
                }
                Tag {
                    text: output.data["block_height"]
                }
            }
            VSpacer {
            }
        }
    }
}
