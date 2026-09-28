import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    property Wallet wallet
    property SignLiquidTransactionResolver resolver

    id: self
    spacing: 16

    Connections {
        target: resolver.deviceTask
        function onMessageChanged({ index, output } = {}) {
            if (output) {
                const is_fee = output.scriptpubkey === ''
                const component = is_fee ? review_fee_component : review_output_component
                stack_view.push(component, { index, output }, StackView.PushTransition)
            } else {
                stack_view.pop()
            }
        }
    }
    DeviceImage {
        Layout.alignment: Qt.AlignCenter
        Layout.preferredHeight: 32
        device: resolver.device
    }
    Loader {
        Layout.alignment: Qt.AlignCenter
        active: resolver.deviceTask
        sourceComponent: ProgressBar {
            from: resolver.deviceTask.progress.from
            to: resolver.deviceTask.progress.to
            value: resolver.deviceTask.progress.value
            indeterminate: resolver.deviceTask.progress.indeterminate
            Behavior on value { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        }
        Behavior on opacity { OpacityAnimator {} }
    }
    StackView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        id: stack_view
        clip: true
        initialItem: Item {
        }
    }
    Component {
        id: review_output_component
        VFlickable {
            required property int index
            required property var output
            readonly property Asset asset: wallet.context.getOrCreateAsset(output.asset_id)
            id: output_view
            alignment: Qt.AlignTop
            spacing: 16
            FieldTitle {
                text: qsTrId('id_review_output_s').arg('#' + (index + 1))
            }
            FieldTitle {
                text: qsTrId('id_amount')
            }
            Pane {
                Layout.fillWidth: true
                padding: 20
                background: Rectangle {
                    color: '#181818'
                    radius: 5
                }
                contentItem: RowLayout {
                    spacing: 16
                    AssetIcon {
                        asset: output_view.asset
                    }
                    Label {
                        Layout.fillWidth: true
                        font.family: 'Roboto Mono'
                        font.features: { 'calt': 0, 'zero': 1 }
                        font.pixelSize: 16
                        font.weight: 400
                        horizontalAlignment: Qt.AlignRight
                        text: output_view.asset.formatAmount(output.satoshi, true, 'BTC')
                    }
                }
            }
            FieldTitle {
                text: output.is_change ? qsTrId('id_change_address') : qsTrId('id_send_to')
            }
            AddressLabel {
                Layout.fillWidth: true
                address: output.address
                bottomPadding: 20
                elide: Label.ElideNone
                leftPadding: 20
                rightPadding: 20
                topPadding: 20
                background: Rectangle {
                    color: '#181818'
                    radius: 5
                }
            }
            FieldTitle {
                visible: !!output.device_address
                text: 'Shown on your Ledger'
            }
            AddressLabel {
                Layout.fillWidth: true
                visible: !!output.device_address
                address: output.device_address
                bottomPadding: 20
                elide: Label.ElideNone
                leftPadding: 20
                rightPadding: 20
                topPadding: 20
                background: Rectangle {
                    color: '#181818'
                    radius: 5
                }
            }
            VSpacer {
            }
        }
    }
    Component {
        id: review_fee_component
        VFlickable {
            required property int index
            required property var output
            readonly property Asset asset: wallet.context.getOrCreateAsset(output.asset_id)
            id: fee_view
            alignment: Qt.AlignTop
            spacing: 16
            FieldTitle {
                text: qsTrId('id_confirm_transaction')
            }
            FieldTitle { text: qsTrId('id_fee') }
            Pane {
                Layout.fillWidth: true
                padding: 20
                background: Rectangle {
                    color: '#181818'
                    radius: 5
                }
                contentItem: RowLayout {
                    spacing: 16
                    AssetIcon {
                        asset: fee_view.asset
                    }
                    Label {
                        Layout.fillWidth: true
                        font.family: 'Roboto Mono'
                        font.features: { 'calt': 0, 'zero': 1 }
                        font.pixelSize: 16
                        font.weight: 400
                        horizontalAlignment: Qt.AlignRight
                        text: fee_view.asset.formatAmount(output.satoshi, true, 'BTC')
                    }
                }
            }
            VSpacer {
            }
        }
    }
}
