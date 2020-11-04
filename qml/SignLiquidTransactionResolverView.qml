import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

Column {
    property SignLiquidTransactionResolver resolver
    property var actions: resolver.failed ? failed_action : null

    spacing: 16

    Action {
        id: failed_action
        text: qsTrId('id_cancel')
        onTriggered: controller_dialog.accept()
    }
    DeviceImage {
        device: resolver.handler.wallet.device
        anchors.horizontalCenter: parent.horizontalCenter
        height: 32
    }
    ProgressBar {
        anchors.horizontalCenter: parent.horizontalCenter
        opacity: resolver.failed ? 0 : 1
        value: resolver.progress
        Behavior on value { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on opacity { OpacityAnimator {} }
    }
    Label {
        opacity: resolver.failed ? 1 : 0
        Behavior on opacity { OpacityAnimator {} }
        anchors.horizontalCenter: parent.horizontalCenter
        text: qsTrId('id_operation_failure')
    }
    Loader {
        visible: active
        active: 'output' in resolver.message && !resolver.message.output.is_fee
        opacity: resolver.failed ? 0 : 1
        Behavior on opacity { OpacityAnimator {} }
        sourceComponent: Column {
            id: output_view
            readonly property var output: resolver.message.output
            readonly property Asset asset: resolver.handler.wallet.getOrCreateAsset(output.asset_id || 'btc')
            spacing: 16
            SectionLabel {
                text: qsTrId('id_review_output_s').arg(resolver.message.index + 1)
            }
            Row {
                spacing: 16
                AssetIcon {
                    asset: output_view.asset
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Label {
                        Layout.fillWidth: true
                        text: output_view.asset.name
                        font.pixelSize: 14
                        elide: Label.ElideRight
                    }

                    Label {
                        visible: 'entity' in output_view.asset.data
                        Layout.fillWidth: true
                        opacity: 0.5
                        text: output_view.asset.data.entity ? output_view.asset.data.entity.domain : ''
                        elide: Label.ElideRight
                    }
                }
            }
            SectionLabel { text: resolver.message.output.is_change ? qsTrIt('id_change_address') : qsTrId('id_recipient_address') }
            Label {
                text: resolver.message.output.address
            }
            SectionLabel { text: qsTrId('id_amount') }
            Label {
                text: output_view.asset.formatAmount(output.satoshi, true, 'BTC')
            }
        }
    }
    Loader {
        visible: active
        active: 'output' in resolver.message && resolver.message.output.is_fee
        opacity: resolver.failed ? 0 : 1
        Behavior on opacity { OpacityAnimator {} }
        sourceComponent: Column {
            id: fee_view
            readonly property var output: resolver.message.output
            readonly property Asset asset: resolver.handler.wallet.getOrCreateAsset(output.asset_id || 'btc')
            spacing: 16
            SectionLabel {
                text: qsTrId('id_confirm_transaction')
            }
            SectionLabel { text: qsTrId('id_fee') }
            Label {
                text: fee_view.asset.formatAmount(output.satoshi, true, 'BTC')
            }
        }
    }
}
