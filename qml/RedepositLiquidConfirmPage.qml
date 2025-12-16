import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

StackViewPage {
    required property Context context
    required property Account account
    required property var transaction
    property bool note: controller.memo.length > 0
    StackView.onActivated: controller.cancel()
    TaskPageFactory {
        title: self.title
        monitor: controller.monitor
        target: self.StackView.view
        onClosed: self.closeClicked()
    }
    SignTransactionController {
        id: controller
        context: self.context
        account: self.account
        transaction: self.transaction
        memo: note_text_area.text
        onTransactionCompleted: transaction => {
            Analytics.recordEvent('send_transaction', AnalyticsJS.segmentationTransaction(Settings, self.account, {
                transaction_type: 'redeposit',
                with_memo: controller.memo.length > 0,
            }))
            // TODO: should replace but we must cut dependency to the current view
            self.StackView.view.push(transaction_completed_page, { transaction })
        }
        onFailed: (error) => {
            const segmentation = AnalyticsJS.segmentationSubAccount(Settings, self.account)
            segmentation.error = error
            Analytics.recordEvent('failed_transaction', segmentation)
            self.StackView.view.push(error_page, { error })
        }
    }
    AnalyticsView {
        name: 'SendConfirm'
        active: self.StackView.visible
        segmentation: AnalyticsJS.segmentationSubAccount(Settings, self.account)
    }
    id: self
    title: qsTrId('id_confirm_transaction')
    rightItem: CloseButton {
        onClicked: self.closeClicked()
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
                alert: AnalyticsAlert {
                    screen: 'SendConfirm'
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
                    color: '#262626'
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
                text: qsTrId('id_addresses')
            }
            Repeater {
                model: self.transaction.transaction_outputs.filter(output => output.scriptpubkey.length > 0)
                delegate: Pane {
                    required property var modelData
                    readonly property Address address: self.account.getOrCreateAddress(delegate.modelData)
                    readonly property Asset asset: self.account.context.getOrCreateAsset(delegate.modelData.asset_id)
                    Layout.fillWidth: true
                    id: delegate
                    padding: 20
                    background: Rectangle {
                        color: '#262626'
                        radius: 5
                    }
                    contentItem: ColumnLayout {
                        spacing: 10
                        AddressLabel {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            address: delegate.address
                        }
                        RowLayout {
                            Layout.alignment: Qt.AlignCenter
                            Layout.fillWidth: false
                            visible: delegate.address.verified
                            Image {
                                Layout.alignment: Qt.AlignCenter
                                source: 'qrc:/svg2/seal-check.svg'
                            }
                            Label {
                                font.pixelSize: 14
                                font.weight: 400
                                text: qsTrId('id_verified')
                            }
                        }
                        RowLayout {
                            Convert {
                                id: convert
                                account: self.account
                                input: ({ satoshi: delegate.modelData.satoshi })
                                asset: delegate.asset
                                unit: self.account.session.unit
                            }
                            AssetIcon {
                                Layout.alignment: Qt.AlignCenter
                                asset: delegate.asset
                            }
                            HSpacer {
                            }
                            ColumnLayout {
                                Label {
                                    Layout.alignment: Qt.AlignRight
                                    font.pixelSize: 14
                                    font.weight: 600
                                    text: convert.output.label
                                }
                                Label {
                                    Layout.alignment: Qt.AlignRight
                                    color: '#929292'
                                    font.pixelSize: 14
                                    font.weight: 600
                                    text: convert.fiat.label
                                    visible: convert.fiat.available
                                }
                            }
                        }
                        RegularButton {
                            Layout.alignment: Qt.AlignCenter
                            leftPadding: 8
                            rightPadding: 8
                            topPadding: 0
                            bottomPadding: 0
                            font.pixelSize: 12
                            font.weight: 400
                            visible: controller.context?.wallet?.login?.device?.type === 'jade' && !delegate.address.verified
                            text: qsTrId('id_verify_on_device')
                            onClicked: {
                                self.StackView.view.push(jade_verify_page, { context: self.context, address: delegate.address })
                                Analytics.recordEvent('verify_address', AnalyticsJS.segmentationSubAccount(Settings, self.account))
                            }
                        }
                    }
                }
            }
            LinkButton {
                Layout.alignment: Qt.AlignCenter
                Layout.topMargin: 15
                text: qsTrId('id_add_note')
                visible: !self.note
                onClicked: {
                    self.note = true
                    note_text_area.forceActiveFocus()
                }
            }
            FieldTitle {
                text: qsTrId('id_note')
                visible: self.note
            }
            GTextArea {
                Layout.fillWidth: true
                id: note_text_area
                visible: self.note
                wrapMode: TextArea.Wrap
            }
        }
    }
    footerItem: ColumnLayout {
        spacing: 10
        Convert {
            id: fee_convert
            account: self.account
            input: ({ satoshi: String(self.transaction.fee) })
            unit: self.account.session.unit
        }
        Convert {
            id: total_convert
            account: self.account
            input: {
                const network = self.account.network
                const total = self.transaction.fee - (self.transaction.satoshi[network.liquid ? network.policyAsset : 'btc'] ?? 0)
                return { satoshi: String(total) }
            }
            unit: self.account.session.unit
        }
        RowLayout {
            Layout.fillWidth: true
            Label {
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true
                font.pixelSize: 14
                font.weight: 500
                opacity: 0.5
                text: qsTrId('id_network_fee')
            }
            ColumnLayout {
                Label {
                    Layout.alignment: Qt.AlignRight
                    opacity: 0.5
                    font.pixelSize: 14
                    font.weight: 500
                    text: fee_convert.output.label
                }
                Label {
                    Layout.alignment: Qt.AlignRight
                    opacity: 0.5
                    font.pixelSize: 12
                    font.weight: 400
                    text: '~ ' + fee_convert.fiat.label
                }
            }
        }
        Rectangle {
            Layout.preferredHeight: 1
            Layout.fillWidth: true
            opacity: 0.4
            color: '#FFF'
        }
        RowLayout {
            Layout.fillWidth: true
            Label {
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true
                font.pixelSize: 14
                font.weight: 500
                opacity: 0.5
                text: qsTrId('id_total')
            }
            ColumnLayout {
                Label {
                    Layout.alignment: Qt.AlignRight
                    font.pixelSize: 14
                    font.weight: 500
                    text: total_convert.output.label
                }
                Label {
                    Layout.alignment: Qt.AlignRight
                    font.pixelSize: 14
                    font.weight: 500
                    opacity: 0.5
                    text: '~ ' + total_convert.fiat.label
                }
            }
        }
        PrimaryButton {
            Layout.alignment: Qt.AlignCenter
            Layout.minimumWidth: 200
            Layout.topMargin: 20
            enabled: controller.monitor?.idle ?? true
            busy: !(controller.monitor?.idle ?? true)
            text: qsTrId('id_confirm_transaction')
            onClicked: controller.sign()
        }
        RowLayout {
            Layout.fillWidth: false
            Layout.alignment: Qt.AlignCenter
            opacity: 0.6
            Image {
                source: 'qrc:/svg2/info.svg'
            }
            Label {
                font.pixelSize: 12
                font.weight: 400
                text: qsTrId('id_fees_are_collected_by_bitcoin')
            }
        }
    }

    Component {
        id: jade_verify_page
        JadeVerifyAddressPage {
        }
    }

    Component {
        id: error_page
        ErrorPage {
            title: self.title
        }
    }

    Component {
        id: transaction_completed_page
        TransactionCompletedPage {
            onCloseClicked: self.closeClicked()
        }
    }
}
