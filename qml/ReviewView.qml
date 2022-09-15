import Blockstream.Green 0.1
import QtMultimedia 5.13
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

ScrollView {
    property list<Action> actions: [
        Action {
            text: qsTrId('id_back')
            onTriggered: stack_view.pop()
        },
        Action {
            text: qsTrId('id_send')
            onTriggered: controller.signAndSend()
        }
    ]

    id: scroll_view
    clip: true

    AnalyticsView {
        name: 'SendConfirm'
        active: true
        segmentation: segmentationSubAccount(controller.account)
    }

    ColumnLayout {
        spacing: 16
        width: Math.max(implicitWidth, scroll_view.availableWidth)

        SectionLabel { text: qsTrId('id_fee') }
        Label {
            text: formatAmount(controller.transaction.fee) + ' ≈ ' +
                  formatFiat(controller.transaction.fee)
        }
        Repeater {
            model: controller.transaction._addressees
            delegate: wallet.network.liquid ? liquid_address : bitcoin_address
        }
        SectionLabel { text: qsTrId('id_my_notes') }
        ScrollView {
            Layout.fillWidth: true
            Layout.maximumHeight: 64
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            ScrollBar.vertical.interactive: hovered
            GTextArea {
                id: memo_edit
                Layout.fillWidth: true
                selectByMouse: true
                wrapMode: TextEdit.Wrap
                text: controller.memo
                onTextChanged: {
                    if (text.length > 1024) {
                        text = text.slice(0, 1024);
                    }
                    controller.memo = memo_edit.text;
                }
            }
        }
    }

    Component {
        id: bitcoin_address
        ColumnLayout {
            spacing: 16
            SectionLabel { text: qsTrId('id_address') }
            Label { text: modelData.address }
            SectionLabel { text: qsTrId('id_amount') }
            Label {
                text: formatAmount(modelData.satoshi) + ' ≈ ' +
                      formatFiat(modelData.satoshi)
            }
        }
    }

    Component {
        id: liquid_address
        ColumnLayout {
            property Asset address_asset: wallet.getOrCreateAsset(modelData.asset_id)
            spacing: 8
            SectionLabel { text: qsTrId('id_address') }
            Label { text: modelData.address }
            SectionLabel { text: qsTrId('id_asset') }
            RowLayout {
                spacing: 8
                AssetIcon {
                    asset: address_asset
                }
                Label {
                    text: address_asset.name
                    elide: Label.ElideMiddle
                }
            }
            SectionLabel { text: qsTrId('id_amount') }
            Label {
                text: {
                    wallet.displayUnit
                    return address_asset.formatAmount(modelData.satoshi, true, wallet.settings.unit)
                }
            }
        }
    }
}
