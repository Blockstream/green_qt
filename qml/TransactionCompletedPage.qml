import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    id: self
    required property ContextTransaction transaction
    property string message: qsTrId('id_successfully_sent_your_funds')
    readonly property string txhash: self.transaction?.data?.txhash ?? ''
    readonly property string explorerUrl: String(self.transaction?.url ?? '')
    leftItem: Item {}
    centerItem: Item {}
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    footerItem: ColumnLayout {
        spacing: 28
        PrimaryButton {
            Layout.fillWidth: true
            text: qsTrId('id_done')
            onClicked: self.closeClicked()
        }
        LinkButton {
            Layout.alignment: Qt.AlignCenter
            font.pixelSize: 16
            external: true
            text: qsTrId('id_view_in_explorer')
            visible: self.explorerUrl.length > 0
            onClicked: Qt.openUrlExternally(self.explorerUrl)
        }
    }
    contentItem: ColumnLayout {
        spacing: 48
        CompletedImage {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 100
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12
            Label {
                Layout.fillWidth: true
                font.pixelSize: 24
                font.weight: 700
                horizontalAlignment: Label.AlignHCenter
                text: qsTrId('id_transaction_sent')
                wrapMode: Label.WordWrap
            }
            Label {
                Layout.fillWidth: true
                color: '#A0A0A0'
                font.pixelSize: 16
                font.weight: 400
                horizontalAlignment: Label.AlignHCenter
                text: self.message
                visible: self.message.length > 0
                wrapMode: Label.WordWrap
            }
        }
        TransactionIdPane {
            Layout.fillWidth: true
            txhash: self.txhash
            visible: self.txhash.length > 0
        }
        VSpacer {}
    }

    component TransactionIdPane: Pane {
        id: tx_id_pane
        required property string txhash
        padding: 0
        background: Item {}
        contentItem: ColumnLayout {
            spacing: 12
            RowLayout {
                Layout.alignment: Qt.AlignCenter
                spacing: 8
                Label {
                    color: '#A0A0A0'
                    font.pixelSize: 16
                    font.weight: 400
                    text: qsTrId('id_transaction_id') + ':'
                }
                AbstractButton {
                    id: copy_button
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    opacity: copy_button.hovered ? 1 : 0.6
                    icon.source: copy_timer.running ? 'qrc:/svg2/check.svg' : 'qrc:/svg2/copy.svg'
                    onClicked: {
                        Clipboard.copy(tx_id_pane.txhash)
                        copy_timer.restart()
                    }
                    Timer {
                        id: copy_timer
                        interval: 1000
                        repeat: false
                    }
                    contentItem: Image {
                        source: copy_button.icon.source
                    }
                }
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.maximumWidth: 308
                color: '#FFFFFF'
                font.family: 'Roboto Mono'
                font.pixelSize: 14
                font.weight: 400
                horizontalAlignment: Label.AlignHCenter
                text: tx_id_pane.txhash
                wrapMode: Label.WrapAnywhere
            }
        }
    }
}
