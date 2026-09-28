import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS

VFlickable {
    required property Wallet wallet
    required property SignTransactionResolver resolver
    readonly property var inputs: resolver.requiredData.transaction_inputs
    readonly property var outputs: resolver.requiredData.transaction_outputs

    id: self
    alignment: Qt.AlignTop
    spacing: 16

    AnalyticsView {
        active: true
        name: 'VerifyTransaction'
        segmentation: AnalyticsJS.segmentationSession(self.resolver.session.context)
    }

    DeviceImage {
        Layout.alignment: Qt.AlignCenter
        Layout.preferredHeight: 32
        device: resolver.device
    }
    Repeater {
        model: outputs
        delegate: Page {
            Layout.fillWidth: true
            background: null
            header: FieldTitle {
                bottomPadding: constants.s1
                text: 'Output ' + (index + 1) + '/' + outputs.length
            }
            contentItem: ColumnLayout {
                FieldTitle {
                    text: qsTrId('id_to')
                }
                AddressLabel {
                    Layout.fillWidth: true
                    address: modelData.address
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
                    text: qsTrId('id_amount')
                }
                Label {
                    Layout.fillWidth: true
                    text: wallet.formatAmount(modelData.satoshi, true, 'btc')
                }
            }
        }
    }
    Page {
        Layout.fillWidth: true
        background: null
        header: FieldTitle {
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
                text: wallet.formatAmount(self.resolver.task.details.fee, true, 'btc')
            }
        }
    }
    Repeater {
        model: !self.resolver.session.network.mainnet && !self.resolver.session.network.electrum ? inputs : []
        delegate: Page {
            Layout.fillWidth: true
            background: null
            header: FieldTitle {
                bottomPadding: constants.s1
                text: 'Input ' + (index + 1) + '/' + inputs.length
            }
            contentItem: GridLayout {
                columnSpacing: constants.s1
                rowSpacing: constants.s1
                columns: 2
                Label {
                    text: qsTrId('id_path_used_for_signing')
                }
                Label {
                    Layout.fillWidth: true
                    text: modelData.user_path.map(i => i < 2147483648 ? i : (i - 2147483648) + '\'').join('/')
                }
            }
        }
    }
}
