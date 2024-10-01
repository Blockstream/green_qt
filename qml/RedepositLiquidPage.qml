import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

StackViewPage {
    signal closed()
    required property Context context
    required property Account account

    FeeEstimates {
        id: estimates
        session: self.account.session
    }
    RedepositController {
        id: controller
        context: self.context
        account: self.account
    }
    AnalyticsView {
        name: 'Send'
        active: self.StackView.visible
        segmentation: AnalyticsJS.segmentationSubAccount(Settings, self.account)
    }
    id: self
    title: qsTrId('id_redeposit')
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
            width: flickable.width
            AlertView {
                Layout.bottomMargin: 15
                alert: AnalyticsAlert {
                    screen: 'Redeposit'
                    network: self.account.network.id
                }
            }
            FieldTitle {
                text: qsTrId('id_account')
            }
            Pane {
                Layout.bottomMargin: 15
                Layout.fillWidth: true
                padding: 20
                background: Rectangle {
                    color: '#222226'
                    radius: 5
                }
                contentItem: RowLayout {
                    spacing: 10
                    Image {
                        Layout.alignment: Qt.AlignCenter
                        Layout.maximumWidth: 32
                        Layout.maximumHeight: 32
                        source: UtilJS.iconFor(self.account)
                    }
                    ColumnLayout {
                        Layout.alignment: Qt.AlignCenter
                        Layout.fillHeight: false
                        spacing: 0
                        Label {
                            font.pixelSize: 16
                            font.weight: 600
                            text: self.account?.network?.displayName ?? '-'
                        }
                        Label {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            Layout.topMargin: 4
                            font.capitalization: Font.AllUppercase
                            font.pixelSize: 12
                            font.weight: 500
                            opacity: 0.4
                            text: UtilJS.accountName(self.account)
                            wrapMode: Label.Wrap
                        }
                        Label {
                            font.capitalization: Font.AllUppercase
                            font.pixelSize: 11
                            font.weight: 400
                            opacity: 0.4
                            text: UtilJS.networkLabel(self.account?.network) + ' / ' + UtilJS.accountLabel(self.account)
                        }
                    }
                }
            }
            FieldTitle {
                text: qsTrId('id_assets')
                visible: controller.transaction?.satoshi ?? false
            }
            Pane {
                Layout.bottomMargin: 15
                Layout.fillWidth: true
                padding: 20
                visible: controller.transaction?.satoshi ?? false
                background: Rectangle {
                    color: '#222226'
                    radius: 5
                }
                contentItem: ColumnLayout {
                    spacing: 10
                    Repeater {
                        model: Object.keys(controller.transaction?.satoshi ?? {})
                        delegate: RowLayout {
                            required property var modelData
                            readonly property Asset asset: self.context.getOrCreateAsset(delegate.modelData)
                            id: delegate
                            spacing: 20
                            AssetIcon {
                                asset: delegate.asset
                            }
                            Label {
                                Layout.alignment: Qt.AlignCenter
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                color: delegate.asset.name ? '#FFF' : '#929292'
                                font.pixelSize: 14
                                font.weight: 600
                                text: delegate.asset.name || delegate.asset.id
                                elide: Label.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }
    footerItem: ColumnLayout {
        Convert {
            id: fee_convert
            account: controller.account
            input: ({ satoshi: String(controller.transaction.fee ?? 0) })
            unit: controller.account.session.unit
        }
        RowLayout {
            Label {
                font.pixelSize: 14
                font.weight: 500
                text: qsTrId('id_network_fee')
            }
            HSpacer {
            }
            Label {
                font.pixelSize: 14
                font.weight: 500
                text: fee_convert.output.label
            }
        }
        RowLayout {
            Layout.bottomMargin: 20
            Label {
                color: '#6F6F6F'
                font.pixelSize: 14
                font.weight: 400
                text: {
                    if (controller.feeRate < estimates.fees[24]) {
                        return qsTrId('id_custom')
                    }
                    if (controller.feeRate < estimates.fees[12]) {
                        return qsTrId('id_4_hours')
                    }
                    if (controller.feeRate < estimates.fees[3]) {
                        return qsTrId('id_2_hours')
                    }
                    return qsTrId('id_1030_minutes')
                }
                visible: !controller.account.network.liquid
            }
            LinkButton {
                text: qsTrId('id_change_speed')
                visible: !controller.account.network.liquid
                onClicked: self.pushSelectFeePage()
            }
            HSpacer {
            }
            Label {
                color: '#6F6F6F'
                font.pixelSize: 12
                font.weight: 400
                text: '~ ' + fee_convert.fiat.label
            }
        }
        ErrorPane {
            error: {
                const error = controller.transaction?.error
                if (error === 'id_invalid_replacement_fee_rate') return error
                if (error === 'Insufficient funds for fees') return error
            }
        }
        RowLayout {
            spacing: 20
            PrimaryButton {
                Layout.fillWidth: true
                enabled: (controller.transaction?.transaction?.length ?? 0) > 0
                implicitWidth: 0
                text: qsTrId('id_next')
                onClicked: {
                    self.StackView.view.push(confirm_page, {
                        context: self.context,
                        account: controller.account,
                        transaction: controller.transaction,
                    })
                }
            }
        }
    }

    Component {
        id: confirm_page
        RedepositLiquidConfirmPage {
            onClosed: self.closed()
        }
    }

    component ErrorPane: Collapsible {
        required property var error
        Layout.fillWidth: true
        id: error_pane
        animationVelocity: 300
        contentWidth: error_pane.width
        contentHeight: pane.height
        collapsed: !error_pane.error
        z: -1
        Pane {
            id: pane
            leftPadding: 10
            rightPadding: 10
            bottomPadding: 15
            topPadding: error_pane.Layout.topMargin !== 0 ? 25 : 15
            width: error_pane.width
            background: Rectangle {
                color: '#3B080F'
                radius: 5
            }
            contentItem: RowLayout {
                spacing: 10
                Image {
                    source: 'qrc:/svg2/info_red.svg'
                }
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    font.pixelSize: 12
                    font.weight: 600
                    color: '#C91D36'
                    text: qsTrId(error_pane.error ?? '')
                    wrapMode: Label.Wrap
                }
            }
        }
    }
}
