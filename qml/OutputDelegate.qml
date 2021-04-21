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
            AssetIcon {
                asset: output.asset
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
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
                    visible: output.data["user_status"]===1
                    text: "FROZEN"
                }
                Tag {
                    text: "DUST"
                    visible: output.data["satoshi"]<1092
                }
                Tag {
                    text: "NOT CONFIDENTIAL"
                    visible: output.data["confidential"]===false
                }
                Tag {
                    text: output.data["address_type"]
                    font.capitalization: Font.AllUppercase
                }
                Tag {
                    text: "2FA EXPIRED"
                    visible: {
                        if (output.data["address_type"]==="csv") {
                             return (output.data["block_height"] + output.data["subtype"]) < output.data["current_block_height"]
                        }
                        else {
                             return output.data["nlocktime_at"]===0
                        }
                    }
                }
                Tag {
                    text: output.data["block_height"]
                }
            }

            VSpacer {
            }

            /*
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: constants.p1
                elide: Text.ElideRight
                text: output.data["txhash"]
                font.pixelSize: 14
                font.styleName: 'Regular'
            }
            Label {
                text: output.data["satoshi"]
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 14
                font.capitalization: Font.AllUppercase
                font.styleName: 'Regular'
                Layout.minimumWidth: 50
            }
            */
        }
    }
}
