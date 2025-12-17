import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    signal selected(var mnemonic)
    required property var mnemonic
    property int size: 12
    property int columns: self.size / 6

    id: self
    title: 'Backup'
    footerItem: ColumnLayout {
        Image {
            Layout.topMargin: 20
            Layout.alignment: Qt.AlignCenter
            source: 'qrc:/svg2/house.svg'
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            font.pixelSize: 12
            font.weight: 600
            text: qsTrId('id_make_sure_to_be_in_a_private')
        }
    }
    contentItem: VFlickable {
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            horizontalAlignment: Label.AlignHCenter
            font.pixelSize: 24
            font.weight: 600
            text: qsTrId('id_write_down_your_recovery_phrase')
            wrapMode: Label.Wrap
        }
        Label {
            Layout.fillWidth: true
            Layout.topMargin: 20
            horizontalAlignment: Label.AlignHCenter
            font.pixelSize: 14
            font.weight: 600
            opacity: 0.4
            text: qsTrId('id_store_it_somewhere_safe')
            wrapMode: Label.Wrap
        }
        MnemonicSizeSelector {
            Layout.topMargin: 20
            Layout.alignment: Qt.AlignCenter
            id: selector
            size: self.size
            visible: !self.mnemonic
            onSizeClicked: (size) => { self.size = size }
        }
        Pane {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 20
            background: null
            contentItem: MnemonicView {
                id: mnemonic_view
                columns: self.columns
                mnemonic: self.mnemonic ?? WalletManager.generateMnemonic(self.size)
            }
        }
        PrimaryButton {
            Layout.alignment: Qt.AlignCenter
            Layout.minimumWidth: 250
            Layout.topMargin: 20
            text: qsTrId('id_next')
            onClicked: self.selected(mnemonic_view.mnemonic)
        }
    }
}
