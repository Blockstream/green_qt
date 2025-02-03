import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    signal feeRateSelected(int fee_rate)
    required property Account account
    required property string unit
    required property int size
    required property Transaction previousTransaction
    property bool custom: false
    readonly property real minimumFeeRate: estimates.fees[0] + (self.previousTransaction?.data?.fee_rate ?? 0)
    id: self
    title: qsTrId('id_network_fee')
    FeeEstimates {
        id: estimates
        session: self.account.session
    }
    contentItem: ColumnLayout {
        spacing: 10
        FeeRateButton {
            name: qsTrId('id_fast')
            rate: estimates.fees[3]
            time: qsTrId('id_1030_minutes')
        }
        FeeRateButton {
            name: qsTrId('id_medium')
            rate: estimates.fees[12]
            time: qsTrId('id_2_hours')
        }
        FeeRateButton {
            name: qsTrId('id_slow')
            rate: estimates.fees[24]
            time: qsTrId('id_4_hours')
        }
        LinkButton {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 20
            text: qsTrId('id_custom')
            visible: !self.custom && !self.previousTransaction
            onClicked: self.custom = true
        }
        Pane {
            Layout.fillWidth: true
            Layout.topMargin: 20
            padding: 20
            visible: self.custom || self.previousTransaction
            background: Rectangle {
                color: '#2F2F35'
                radius: 5
            }
            contentItem: ColumnLayout {
                spacing: 10
                Label {
                    Layout.alignment: Qt.AlignCenter
                    font.pixelSize: 16
                    font.weight: 600
                    text: qsTrId('id_set_custom_fee_rate')
                }
                Slider {
                    Layout.fillWidth: true
                    id: slider
                    from: self.minimumFeeRate
                    to: Math.max(estimates.fees[1], self.previousTransaction?.data?.fee_rate ?? 0) * 2
                    stepSize: 100
                }
                RowLayout {
                    ColumnLayout {
                        Layout.alignment: Qt.AlignCenter
                        RowLayout {
                            Label {
                                Layout.alignment: Qt.AlignCenter
                                text: qsTrId('id_custom')
                                font.pixelSize: 16
                                font.weight: 600
                            }
                            HSpacer {
                            }
                        }
                        Label {
                            font.pixelSize: 12
                            font.weight: 400
                            text: UtilJS.formatFeeRate(slider.value, self.account.network)
                            opacity: 0.6
                        }
                    }
                    ColumnLayout {
                        Layout.alignment: Qt.AlignCenter
                        visible: self.size > 0
                        Label {
                            Layout.alignment: Qt.AlignRight
                            text: '~ ' + convert.output.label
                            font.pixelSize: 16
                            font.weight: 600
                        }
                        Convert {
                            id: convert
                            account: self.account
                            input: ({ satoshi: String(Math.round(slider.value * self.size / 1000)) })
                            unit: self.unit
                        }
                        Label {
                            Layout.alignment: Qt.AlignRight
                            font.pixelSize: 12
                            font.weight: 400
                            text: '~ ' + convert.fiat.label
                            opacity: 0.6
                        }
                    }
                }
                PrimaryButton {
                    Layout.alignment: Qt.AlignCenter
                    Layout.minimumWidth: 150
                    Layout.topMargin: 20
                    text: qsTrId('id_save')
                    onClicked: self.feeRateSelected(slider.value)
                }
            }
        }

        VSpacer {
        }
    }

    component FeeRateButton: AbstractButton {
        required property var name
        required property var time
        required property var rate
        Layout.fillWidth: true
        id: button
        padding: 20
        visible: button.rate >= self.minimumFeeRate
        onClicked: self.feeRateSelected(button.rate)
        background: Rectangle {
            color: Qt.lighter('#2F2F35', button.hovered ? 1.1 : 1)
            radius: 5
        }
        contentItem: RowLayout {
            spacing: 10
            ColumnLayout {
                Layout.alignment: Qt.AlignCenter
                RowLayout {
                    Label {
                        Layout.alignment: Qt.AlignCenter
                        text: button.name
                        font.pixelSize: 16
                        font.weight: 600
                    }
                    Label {
                        Layout.alignment: Qt.AlignCenter
                        text: button.time
                        font.pixelSize: 12
                        font.weight: 400
                        leftPadding: 8
                        rightPadding: 8
                        topPadding: 2
                        bottomPadding: 2
                        background: Rectangle {
                            radius: height / 2
                            border.width: 1
                            border.color: Qt.alpha('#FFF', 0.2)
                            color: Qt.alpha('#5B5B5B', 0.2)
                        }
                    }
                    HSpacer {
                    }
                }
                Label {
                    font.pixelSize: 12
                    font.weight: 400
                    text: UtilJS.formatFeeRate(button.rate, self.account.network)
                    opacity: 0.6
                }
            }
            ColumnLayout {
                Layout.alignment: Qt.AlignCenter
                visible: self.size > 0
                Label {
                    Layout.alignment: Qt.AlignRight
                    text: '~ ' + convert.output.label
                    font.pixelSize: 16
                    font.weight: 600
                }
                Convert {
                    id: convert
                    account: self.account
                    input: ({ satoshi: String(Math.round(button.rate * self.size / 1000)) })
                    unit: self.unit
                }
                Label {
                    Layout.alignment: Qt.AlignRight
                    font.pixelSize: 12
                    font.weight: 400
                    text: '~ ' + convert.fiat.label
                    opacity: 0.6
                }
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                visible: self.enabled
                source: 'qrc:/svg2/next_arrow.svg'
            }
        }
    }
}
