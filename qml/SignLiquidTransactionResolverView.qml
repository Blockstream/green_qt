import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

Column {
    property Wallet wallet
    property SignLiquidTransactionResolver resolver

    id: self
    spacing: 16

    Connections {
        target: resolver.activity
        function onMessageChanged({ index, output } = {}) {
            if (output) {
                const component = output.is_fee ? review_fee_component : review_output_component
                stack_view.push(component, { index, output }, StackView.PushTransition)
            } else {
                stack_view.pop()
            }
        }
    }
    DeviceImage {
        device: resolver.device
        anchors.horizontalCenter: parent.horizontalCenter
        height: 32
    }
    Loader {
        active: resolver.activity
        anchors.horizontalCenter: parent.horizontalCenter
        // TODO failed property removed from resolver
        sourceComponent: ProgressBar {
            from: resolver.activity.progress.from
            to: resolver.activity.progress.to
            value: resolver.activity.progress.value
            indeterminate: resolver.activity.progress.indeterminate
            Behavior on value { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        }
        Behavior on opacity { OpacityAnimator {} }
    }
//    Label {
//        // TODO failed property removed from resolver
//        opacity: resolver.failed ? 1 : 0
//        Behavior on opacity { OpacityAnimator {} }
//        anchors.horizontalCenter: parent.horizontalCenter
//        text: qsTrId('id_operation_failure')
//    }
    StackView {
        id: stack_view
        clip: true
        implicitHeight: currentItem.implicitHeight
        implicitWidth: currentItem.implicitWidth
        initialItem: Item {
        }
    }
    Component {
        id: review_output_component
        Column {
            id: output_view
            property var output
            property int index
            readonly property Asset asset: wallet.context.getOrCreateAsset(output.asset_id)
            spacing: 16
            SectionLabel {
                text: qsTrId('id_review_output_s').arg('#' + (index + 1))
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
            SectionLabel { text: qsTrId('id_amount') }
            Label {
                text: output_view.asset.formatAmount(output.satoshi, true, 'BTC')
            }
            SectionLabel { text: output.is_change ? qsTrId('id_change_address') : qsTrId('id_recipient_address') }
            Label {
                text: output.address
            }
        }
    }
    Component {
        id: review_fee_component
        Column {
            id: fee_view
            property var output
            readonly property Asset asset: wallet.context.getOrCreateAsset(output.asset_id)
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
