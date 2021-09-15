import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12
import QtQml.Models 2.11

Button {
    required property var output

    function toggleSelection() {
        selection_model.select(output_model.index(output_model.indexOf(output), 0), ItemSelectionModel.Toggle)
    }

    function formatAmount(amount, include_ticker = true) {
        const unit = wallet.settings.unit;
        return output.account.wallet.network.liquid ? output.asset.formatAmount(amount, true) : wallet.formatAmount(amount || 0, include_ticker, unit)
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
                visible: !output.account.wallet.network.liquid
                sourceSize.height: 36
                sourceSize.width: 36
                source: icons[wallet.network.key]
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
            RowLayout {
                Label {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: formatAmount(output.data['satoshi'], true)
                    font.pixelSize: 14
                    font.styleName: 'Medium'
                }
                RowLayout {
                    Tag {
                        color: constants.r500
                        visible: output.expired
                        text: qsTrId('2FA Expired')
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
                        visible: output.account.wallet.network.liquid && !output.confidential
                        font.capitalization: Font.AllUppercase
                    }
                    Tag {
                        text: output.addressType === 'csv' ? qsTrId('id_csv') : qsTrId('id_p2wsh')
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
            Label {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: output.data['txhash'] + ':' + output.data['pt_idx']
                font.pixelSize: 12
                font.styleName: 'Regular'
            }
        }
    }
}
