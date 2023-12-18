import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtQml.Models

import "util.js" as UtilJS

ItemDelegate {
    required property var output

    function formatAmount(amount, include_ticker = true) {
        if (output.account.network.liquid) {
            return output.asset.formatAmount(amount, true)
        } else {
            output.account.session.displayUnit
            return wallet.formatAmount(amount || 0, include_ticker, output.account.session.unit)
        }
    }

    id: self
    hoverEnabled: false
    leftPadding: 20
    rightPadding: 20
    topPadding: 20
    bottomPadding: 20
    background: Rectangle {
        color: '#34373E'
        radius: 5
    }
    contentItem: RowLayout {
        spacing: 20
        CheckBox {
            Layout.alignment: Qt.AlignCenter
            contentItem: null
            enabled: false
            checked: self.checked
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: constants.p1
            RowLayout {
                Tag2 {
                    visible: output.expired
                    text: qsTrId('id_2fa_expired')
                    font.capitalization: Font.AllUppercase
                }
                Tag2 {
                    visible: output.locked
                    text: qsTrId('id_locked')
                    font.capitalization: Font.AllUppercase
                }
                Tag2 {
                    text: qsTrId('id_dust')
                    visible: output.dust
                    font.capitalization: Font.AllUppercase
                }
                Tag2 {
                    text: qsTrId('id_not_confidential')
                    visible: output.account.network.liquid && !output.confidential
                    font.capitalization: Font.AllUppercase
                }
                Tag2 {
                    text: localizedLabel(output.addressType)
                    font.capitalization: Font.AllUppercase
                }
                Tag2 {
                    visible: output.unconfirmed
                    text: qsTrId('id_unconfirmed')
                    color: '#d2934a'
                    font.capitalization: Font.AllUppercase
                }
                HSpacer {
                }
            }
            RowLayout {
                spacing: 10
                Label {
                    Layout.alignment: Qt.AlignCenter
                    text: formatAmount(output.data['satoshi'], true)
                    font.pixelSize: 16
                    font.weight: 600
                }
                Image {
                    Layout.alignment: Qt.AlignCenter
                    Layout.maximumWidth: 20
                    Layout.maximumHeight: 20
                    source: UtilJS.iconFor(output.asset)
                }
                HSpacer {
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                font.pixelSize: 12
                font.weight: 400
                text: self.output.data['txhash'] + ':' + self.output.data['pt_idx']
                wrapMode: Label.Wrap
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                font.pixelSize: 14
                font.weight: 400
                opacity: 0.4
                text: self.output.address
                visible: self.output.address
                wrapMode: Label.Wrap
            }
        }
    }
    component Tag2: Tag {
        background: Rectangle {
            color: 'transparent'
            border.width: 1
            border.color: '#FFF'
            radius: height / 2
        }
        color: 'white'
        opacity: 0.4
    }
}
