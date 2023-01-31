import Blockstream.Green
import QtMultimedia
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS

ColumnLayout {
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
    clip: true
    spacing: 16
    AnalyticsView {
        name: 'SendConfirm'
        active: true
        segmentation: AnalyticsJS.segmentationSubAccount(controller.account)
    }
    AlertView {
        alert: AnalyticsAlert {
            screen: 'SendConfirm'
            network: controller.account.wallet.network.id
        }
    }
    SectionLabel {
        text: qsTrId('id_fee')
    }
    Label {
        text: formatAmount(controller.transaction.fee) + ' ≈ ' + formatFiat(controller.transaction.fee)
    }
    Repeater {
        model: controller.transaction._addressees
        delegate: wallet.network.liquid ? liquid_address : bitcoin_address
    }
    SectionLabel {
        text: qsTrId('id_my_notes')
    }
    ScrollView {
        Layout.fillWidth: true
        Layout.maximumHeight: 128
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
    VSpacer {
        Layout.columnSpan: 2
    }
    Component {
        id: bitcoin_address
        ColumnLayout {
            spacing: 16
            SectionLabel {
                text: qsTrId('id_address')
            }
            Label {
                text: modelData.address
            }
            SectionLabel {
                text: qsTrId('id_amount')
            }
            Label {
                text: formatAmount(modelData.satoshi) + ' ≈ ' + formatFiat(modelData.satoshi)
            }
        }
    }
    Component {
        id: liquid_address
        ColumnLayout {
            property Asset address_asset: wallet.getOrCreateAsset(modelData.asset_id)
            spacing: 8
            SectionLabel {
                text: qsTrId('id_address')
            }
            Label {
                text: modelData.address
            }
            SectionLabel {
                text: qsTrId('id_asset')
            }
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
            SectionLabel {
                text: qsTrId('id_amount')
            }
            Label {
                text: {
                    wallet.displayUnit
                    return address_asset.formatAmount(modelData.satoshi, true, wallet.settings.unit)
                }
            }
        }
    }
}
