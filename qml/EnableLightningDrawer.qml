import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

WalletDrawer {
    property string error: ''

    readonly property bool busy: controller.monitor ? !controller.monitor.idle : false
    readonly property bool detailsVisible: !self.busy && !self.context.lightningEnabled

    id: self

    LightningController {
        id: controller
        context: self.context
    }

    Connections {
        target: controller.monitor
        function onAllFinishedOrFailed() {
            if (!self.error) self.close();
        }
    }

    Connections {
        target: controller
        function onFailed(error) {
            self.error = error
        }
    }

    contentItem: GStackView {
        initialItem: StackViewPage {
            title: 'Lightning Network'
            rightItem: CloseButton {
                onClicked: self.close()
            }
            footer: ColumnLayout {
                spacing: 24
                visible: self.detailsVisible
                PrimaryButton {
                    Layout.fillWidth: true
                    Layout.topMargin: 24
                    text: 'Enable Lightning'
                    onClicked: {
                        self.error = ''
                        controller.enable()
                    }
                }

                LinkButton {
                    Layout.alignment: Qt.AlignHCenter
                    external: true
                    font.pixelSize: 16
                    text: qsTrId('id_learn_more')
                    onClicked: Qt.openUrlExternally('https://help.blockstream.com/hc/en-us/articles/18788578831897-Understand-Lightning-support-in-the-Blockstream-app')
                }
            }
            contentItem: Item {
                VFlickable {
                    anchors.fill: parent
                    alignment: Qt.AlignTop
                    spacing: 32
                    visible: self.detailsVisible

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        Pane {
                            Layout.fillWidth: true
                            visible: self.error !== ''
                            verticalPadding: 12
                            horizontalPadding: 16
                            background: Rectangle {
                                radius: 4
                                color: '#69302E'
                            }
                            contentItem: RowLayout {
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    Label {
                                        Layout.fillWidth: true
                                        color: '#FFFFFF'
                                        font.pixelSize: 14
                                        font.weight: 600
                                        text: 'Failed to enable Lightning'
                                        wrapMode: Label.Wrap
                                    }
                                    Label {
                                        Layout.fillWidth: true
                                        color: '#FFFFFF'
                                        font.pixelSize: 12
                                        font.weight: 400
                                        opacity: 0.6
                                        text: self.error ?? ''
                                        wrapMode: Label.Wrap
                                    }
                                }
                                CloseButton {
                                    Layout.alignment: Qt.AlignCenter
                                    onClicked: self.error = ''
                                }
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            color: '#FFFFFF'
                            font.pixelSize: 20
                            font.weight: 600
                            horizontalAlignment: Label.AlignHCenter
                            lineHeight: 24
                            lineHeightMode: Text.FixedHeight
                            text: 'A scaling solution for faster, cheaper Bitcoin payments.'
                            wrapMode: Label.WordWrap
                        }

                        Image {
                            Layout.preferredHeight: 240
                            Layout.preferredWidth: 400
                            Layout.alignment: Qt.AlignHCenter
                            fillMode: Image.PreserveAspectFit
                            source: 'qrc:/png/lightning_shine.png'
                        }

                        ColumnLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 12

                            FeatureRow {
                                icon: 'qrc:/a0a0a0/24/coins.svg'
                                text: 'Low Fees'
                            }
                            FeatureRow {
                                icon: 'qrc:/a0a0a0/24/bolt.svg'
                                text: 'Instant Transactions'
                            }
                            FeatureRow {
                                icon: 'qrc:/a0a0a0/24/globe.svg'
                                text: 'Global, Permissionless Payments'
                            }
                        }
                    }

                    VSpacer {
                    }

                    Pane {
                        Layout.fillWidth: true
                        leftPadding: 16
                        rightPadding: 16
                        topPadding: 12
                        bottomPadding: 12
                        background: Rectangle {
                            color: '#062F4A'
                            border.color: '#004A70'
                            border.width: 1
                            radius: 8
                        }
                        contentItem: RowLayout {
                            spacing: 12
                            Item {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 40
                                Layout.alignment: Qt.AlignTop
                                Image {
                                    anchors.centerIn: parent
                                    source: 'qrc:/svg2/info_fill_blue.svg'
                                    width: 24
                                    height: 24
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Label {
                                    Layout.fillWidth: true
                                    color: '#FFFFFF'
                                    font.pixelSize: 16
                                    font.weight: 600
                                    text: 'Lightning Is in Beta'
                                    wrapMode: Label.WordWrap
                                }
                                Label {
                                    Layout.fillWidth: true
                                    color: '#A0A0A0'
                                    font.pixelSize: 14
                                    lineHeight: 20
                                    lineHeightMode: Text.FixedHeight
                                    text: 'You may experience bugs or instability during active development.'
                                    wrapMode: Label.WordWrap
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    width: parent.width
                    spacing: 8
                    visible: self.busy
                    BusyIndicator {
                        Layout.alignment: Qt.AlignCenter
                        Layout.preferredHeight: 40
                        Layout.preferredWidth: 40
                    }
                    Label {
                        Layout.fillWidth: true
                        color: '#FFFFFF'
                        font.pixelSize: 16
                        font.weight: 600
                        horizontalAlignment: Label.AlignHCenter
                        text: 'Enabling Lightning...'
                    }
                }
            }
        }
    }
    component FeatureRow: RowLayout {
        required property string icon
        required property string text
        id: feature_row
        spacing: 8
        Image {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            fillMode: Image.PreserveAspectFit
            source: icon
        }
        Label {
            color: '#FAFAFA'
            font.pixelSize: 14
            lineHeight: 20
            lineHeightMode: Text.FixedHeight
            text: feature_row.text
        }
    }
}
