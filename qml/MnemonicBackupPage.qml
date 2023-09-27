import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    signal selected(var mnemonic)
    property int size: 12

    id: self
    rightItem: PrintButton {
        text: 'Print Backup Template'
    }
    contentItem: ColumnLayout {
        Pane {
            Layout.alignment: Qt.AlignCenter
            background: null
            padding: 0
            contentItem: ColumnLayout {
                spacing: 0
                Label {
                    Layout.alignment: Qt.AlignCenter
                    font.family: 'SF Compact Display'
                    font.pixelSize: 24
                    font.weight: 600
                    text: qsTrId('id_write_down_your_recovery_phrase')
                }
                Label {
                    Layout.alignment: Qt.AlignCenter
                    Layout.topMargin: 20
                    font.family: 'SF Compact Display'
                    font.pixelSize: 14
                    font.weight: 600
                    opacity: 0.4
                    text: qsTrId('id_store_it_somewhere_safe')
                }
                MnemonicSizeSelector {
                    Layout.topMargin: 20
                    Layout.alignment: Qt.AlignCenter
                    id: selector
                    onSizeChanged: self.size = selector.size
                }
                Pane {
                    Layout.alignment: Qt.AlignCenter
                    Layout.topMargin: 20
                    background: null
                    contentItem: MnemonicView {
                        id: mnemonic_view
                        rows: 6
                        mnemonic: WalletManager.generateMnemonic(self.size)
                    }
                }
                PrimaryButton {
                    Layout.alignment: Qt.AlignCenter
                    Layout.minimumWidth: 325
                    Layout.topMargin: 20
                    text: qsTrId('id_next')
                    onClicked: self.selected(mnemonic_view.mnemonic)
                }
            }
        }
    }
    footer: ColumnLayout {
        Image {
            Layout.alignment: Qt.AlignCenter
            source: 'qrc:/svg2/house.svg'
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            font.family: 'SF Compact Display'
            font.pixelSize: 12
            font.weight: 600
            text: qsTrId('id_make_sure_to_be_in_a_private')
        }
    }
}
