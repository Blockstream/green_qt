import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "jade.js" as JadeJS

StackViewPage {
    signal closed()
    required property SignLiquidTransactionResolver resolver
    readonly property Wallet wallet: self.resolver.session.context.wallet
    Connections {
        target: self.resolver
        function onFailed() {
            self.StackView.view.pop()
        }
    }
    id: self
    rightItem: CloseButton {
        onClicked: self.closed()
    }
    contentItem: Flickable {
        ScrollIndicator.vertical: ScrollIndicator {
        }
        id: flickable
        clip: true
        contentWidth: flickable.width
        contentHeight: layout.height
        ColumnLayout {
            id: layout
            spacing: 15
            width: flickable.width
            y: Math.max(0, (flickable.height - layout.height) / 2)
            MultiImage {
                Layout.alignment: Qt.AlignCenter
                foreground: JadeJS.image(self.resolver.session.context.device, 7)
                width: 352
                height: 240
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.maximumWidth: 300
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                font.pixelSize: 20
                font.weight: 700
                horizontalAlignment: Label.AlignHCenter
                text: qsTrId('id_confirm_transaction_details_on')
                wrapMode: Label.Wrap
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.maximumWidth: 250
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.bottomMargin: 15
                font.pixelSize: 12
                font.weight: 600
                horizontalAlignment: Label.AlignHCenter
                opacity: 0.6
                text: qsTrId('id_please_follow_the_instructions')
                wrapMode: Label.Wrap
            }
            Repeater {
                model: self.resolver.task.details.transaction_outputs.filter(({ is_change, is_fee, scriptpubkey }) => !is_change && !is_fee && scriptpubkey !== '')
                delegate: ColumnLayout {
                    spacing: 15
                    Convert {
                        id: convert
                        context: self.resolver.session.context
                        asset: self.resolver.session.context.getOrCreateAsset(modelData.asset_id)
                        input: ({ satoshi: String(modelData.satoshi) })
                        unit: 'btc'
                    }
                    RowLayout {
                        spacing: 30
                        Label {
                            Layout.alignment: Qt.AlignVCenter
                            font.pixelSize: 14
                            font.weight: 500
                            opacity: 0.6
                            text: qsTrId('id_address')
                        }
                        Label {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            font.pixelSize: 14
                            font.weight: 500
                            horizontalAlignment: Label.AlignRight
                            text: modelData.address
                            wrapMode: Label.Wrap
                        }
                    }
                    RowLayout {
                        spacing: 20
                        Label {
                            Layout.alignment: Qt.AlignVCenter
                            font.pixelSize: 14
                            font.weight: 500
                            opacity: 0.6
                            text: qsTrId('id_amount')
                        }
                        ColumnLayout {
                            Label {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                font.pixelSize: 14
                                font.weight: 500
                                horizontalAlignment: Label.AlignRight
                                text: convert.output.label
                            }
                            Label {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                font.pixelSize: 14
                                font.weight: 500
                                horizontalAlignment: Label.AlignRight
                                opacity: 0.6
                                text: '~ ' + convert.fiat.label
                                visible: convert.fiat.available
                            }
                        }
                    }
                    RowLayout {
                        spacing: 30
                        Label {
                            Layout.alignment: Qt.AlignVCenter
                            font.pixelSize: 14
                            font.weight: 500
                            opacity: 0.6
                            text: qsTrId('id_asset')
                        }
                        Label {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            font.pixelSize: 14
                            font.weight: 500
                            horizontalAlignment: Label.AlignRight
                            text: {
                                const asset = convert.asset
                                const domain = asset.data?.entity?.domain
                                const parts = [asset.name]
                                if (domain) parts.push(domain)
                                parts.push(asset.id.match(/.{1,8}/g).join(' '))
                                return parts.join('\n')
                            }
                            wrapMode: Label.Wrap
                        }
                    }
                }
            }
            ColumnLayout {
                spacing: 15
                Convert {
                    id: fee_convert
                    context: self.resolver.session.context
                    input: ({ satoshi: String(self.resolver.task.details.fee) })
                    unit: 'btc'
                }
                RowLayout {
                    spacing: 20
                    Label {
                        Layout.alignment: Qt.AlignVCenter
                        font.pixelSize: 14
                        font.weight: 500
                        opacity: 0.6
                        text: qsTrId('id_network_fee')
                    }
                    ColumnLayout {
                        Label {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            font.pixelSize: 14
                            font.weight: 500
                            horizontalAlignment: Label.AlignRight
                            text: fee_convert.output.label
                        }
                        Label {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            font.pixelSize: 14
                            font.weight: 500
                            horizontalAlignment: Label.AlignRight
                            opacity: 0.6
                            text: '~ ' + fee_convert.fiat.label
                        }
                    }
                }
            }
        }
    }
    AnalyticsView {
        active: true
        name: 'VerifyTransaction'
        segmentation: AnalyticsJS.segmentationSession(Settings, self.resolver.session.context)
    }
}
