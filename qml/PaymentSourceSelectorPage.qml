import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    signal sourceClicked(source: PaymentSource)

    required property Context context
    required property list<PaymentSource> sources

    id: self
    title: qsTrId('id_select_account')
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    contentItem: VFlickable {
        alignment: Qt.AlignTop
        spacing: 5
        Repeater {
            model: self.sources
            delegate: SourceButton {
                required property PaymentSource modelData
                Layout.fillWidth: true
                source: modelData
                onClicked: self.sourceClicked(source)
            }
        }
        VSpacer {
        }
    }

    component SourceButton: AbstractButton {
        required property PaymentSource source

        readonly property bool lightning: source.type === PaymentSource.Lightning

        id: button
        padding: 20
        background: Rectangle {
            border.color: '#262626'
            border.width: 1
            color: Qt.lighter('#181818', button.enabled && button.hovered ? 1.2 : 1)
            radius: 8
        }
        contentItem: RowLayout {
            spacing: 12
            AssetIcon {
                Layout.alignment: Qt.AlignCenter
                asset: button.source.asset
                size: 32
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Label {
                    Layout.fillWidth: true
                    color: '#FFFFFF'
                    font.pixelSize: 14
                    font.weight: 500
                    text: button.lightning ? button.source.asset.name : UtilJS.accountName(button.source.account)
                    elide: Label.ElideRight
                }
                Label {
                    Layout.fillWidth: true
                    color: '#A0A0A0'
                    font.pixelSize: 11
                    font.weight: 400
                    text: button.lightning ? qsTrId('id_lightning') : UtilJS.networkLabel(button.source.account.network) + ' / ' + UtilJS.accountLabel(button.source.account)
                    elide: Label.ElideRight
                }
            }
            Convert {
                id: balance_convert
                context: self.context
                account: button.source.account
                asset: button.source.asset
                input: ({ satoshi: String(button.source.balance) })
                unit: UtilJS.unit(self.context)
            }
            ColumnLayout {
                spacing: 2
                Label {
                    Layout.alignment: Qt.AlignRight
                    color: '#FFFFFF'
                    font.pixelSize: 14
                    font.weight: 500
                    text: balance_convert.output.label
                }
                Label {
                    Layout.alignment: Qt.AlignRight
                    color: '#A0A0A0'
                    font.pixelSize: 11
                    font.weight: 400
                    text: balance_convert.fiat.label
                    visible: balance_convert.fiat.available
                }
            }
            RightArrowIndicator {
                active: button.hovered
            }
        }
    }
}
