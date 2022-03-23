import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

GFlickable {
    required property Wallet wallet
    required property SignTransactionResolver resolver
    readonly property var inputs: resolver.requiredData.signing_inputs
    readonly property var outputs: resolver.requiredData.transaction_outputs.filter(({ is_change, is_fee }) => !is_fee)

    id: self
    clip: true
    contentHeight: layout.height
    implicitWidth: layout.implicitWidth

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
                        text: modelData.address
                    }
                    Label {
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
        Repeater {
            model: inputs
            delegate: Page {
                Layout.fillWidth: true
                background: null
                header: SectionLabel {
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
}
