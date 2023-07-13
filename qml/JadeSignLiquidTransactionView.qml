import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS

GFlickable {
    required property Wallet wallet
    required property SignLiquidTransactionResolver resolver
    readonly property var outputs: resolver.outputs.filter(({ is_change, is_fee }) => !is_change && !is_fee)

    id: self
    clip: true
    contentHeight: layout.height
    implicitWidth: layout.implicitWidth

    AnalyticsView {
        active: true
        name: 'VerifyTransaction'
        segmentation: AnalyticsJS.segmentationSession(self.wallet)
    }

    ColumnLayout {
        id: layout
        spacing: constants.s2
        width: availableWidth
        DeviceImage {
            Layout.maximumHeight: 32
            Layout.alignment: Qt.AlignCenter
            device: resolver.device
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            text: qsTrId('id_confirm_transaction_details_on')
        }
        Repeater {
            model: outputs
            delegate: Page {
                readonly property Asset asset: wallet.context.getOrCreateAsset(self.resolver.session.network, modelData.asset_id)
                id: delegate
                Layout.fillWidth: true
                background: null
                header: SectionLabel {
                    bottomPadding: constants.s1
                    text: 'Output ' + (index + 1) + '/' + outputs.length
                }
                contentItem: GridLayout {
                    columnSpacing: constants.s1
                    rowSpacing: constants.s1
                    columns: 2
                    Label {
                        text: qsTrId('id_to')
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        text: modelData.address
                        wrapMode: Text.WrapAnywhere
                    }
                    Label {
                        text: qsTrId('id_amount')
                    }
                    Label {
                        Layout.fillWidth: true
                        text: asset.formatAmount(modelData.satoshi, true, 'btc')
                    }
                    Label {
                        Layout.alignment: Qt.AlignTop
                        text: qsTrId('id_asset')
                    }
                    Label {
                        Layout.fillWidth: true
                        text: [
                            delegate.asset.data.entity?.domain ?? '',
                            String(delegate.asset.id).match(/.{1,8}/g).join(' '),
                        ].join('\n').trim() + '\n'
                    }
                }
            }
        }
        Page {
            Layout.fillWidth: true
            background: null
            header: SectionLabel {
                bottomPadding: constants.s1
                text: 'Summary'
            }
            contentItem: GridLayout {
                columnSpacing: constants.s1
                rowSpacing: constants.s1
                columns: 2
                Label {
                    text: 'Fee'
                }
                Label {
                    Layout.fillWidth: true
                    text: wallet.formatAmount(resolver.transaction.fee, true, 'btc')
                }
            }
        }
    }
}
