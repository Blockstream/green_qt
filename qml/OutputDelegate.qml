import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQml.Models

import "util.js" as UtilJS

ItemDelegate {
    required property var output

    function toggleSelection() {
        if (!output.account.network.liquid) selection_model.select(output_model.index(output_model.indexOf(output), 0), ItemSelectionModel.Toggle)
    }

    function formatAmount(amount, include_ticker = true) {
        if (output.account.network.liquid) {
            return output.asset.formatAmount(amount, true)
        } else {
            wallet.context.displayUnit
            return wallet.formatAmount(amount || 0, include_ticker, wallet.context.settings.unit)
        }
    }

    id: self
    hoverEnabled: true
    padding: constants.p3
    background: Rectangle {
        color: self.hovered ? constants.c700 : self.highlighted ? constants.c600 : constants.c800
        radius: 4
        border.width: self.highlighted ? 1 : 0
        border.color: constants.g500
    }
    onClicked: self.toggleSelection()
    spacing: constants.p2
    contentItem: RowLayout {
        spacing: constants.p2
        ColumnLayout {
            Layout.fillWidth: false
            Layout.fillHeight: false
            Layout.alignment: Qt.AlignTop
            Image {
                visible: !output.account.network.liquid
                sourceSize.height: 36
                sourceSize.width: 36
                source: UtilJS.iconFor(wallet)
            }
            Loader {
                Layout.alignment: Qt.AlignTop
                active: output.asset
                visible: active
                sourceComponent: AssetIcon {
                    asset: output.asset
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                }
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: constants.p1
            Label {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: formatAmount(output.data['satoshi'], true)
                font.pixelSize: 14
                font.styleName: 'Medium'
            }
            Label {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: output.data['txhash'] + ':' + output.data['pt_idx']
                font.pixelSize: 12
                font.styleName: 'Regular'
            }
            RowLayout {
                Tag {
                    color: constants.r500
                    visible: output.expired
                    text: qsTrId('id_2fa_expired')
                    font.capitalization: Font.AllUppercase
                }
                Tag {
                    visible: output.locked
                    text: qsTrId('id_locked')
                    font.capitalization: Font.AllUppercase
                }
                Tag {
                    text: qsTrId('id_dust')
                    visible: output.dust
                    font.capitalization: Font.AllUppercase
                }
                Tag {
                    text: qsTrId('id_not_confidential')
                    visible: output.account.network.liquid && !output.confidential
                    font.capitalization: Font.AllUppercase
                }
                Tag {
                    text: localizedLabel(output.addressType)
                    font.capitalization: Font.AllUppercase
                }
                Tag {
                    visible: output.unconfirmed
                    text: qsTrId('id_unconfirmed')
                    color: '#d2934a'
                    font.capitalization: Font.AllUppercase
                }
            }
        }
    }
}
