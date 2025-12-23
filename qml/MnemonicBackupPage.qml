import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

StackViewPage {
    signal selected(var mnemonic)
    property Context context
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
            font.pixelSize: 18
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
            visible: !self.context
            onSizeClicked: (size) => { self.size = size }
        }
        Pane {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 20
            background: null
            contentItem: MnemonicView {
                id: mnemonic_view
                columns: self.columns
                mnemonic: self.context?.mnemonic ?? WalletManager.generateMnemonic(self.size)
            }
        }
        Bip39Passphrase {
        }
        RegularButton {
            Layout.alignment: Qt.AlignCenter
            Layout.minimumWidth: 250
            Layout.topMargin: 20
            text: qsTrId('id_show_qr_code')
            visible: !!self.context
            onClicked: self.StackView.view.push(qrcode_page)
        }
        PrimaryButton {
            Layout.alignment: Qt.AlignCenter
            Layout.minimumWidth: 250
            Layout.topMargin: 20
            text: qsTrId('id_next')
            onClicked: self.selected(mnemonic_view.mnemonic)
        }
    }

    Component {
        id: qrcode_page
        StackViewPage {
            id: page
            rightItem: CloseButton {
                onClicked: self.closeClicked()
            }
            title: self.title
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
                spacing: 10
                QRCode {
                    Layout.alignment: Qt.AlignHCenter
                    id: qrcode
                    text: self.context?.mnemonic.join(' ')
                    implicitHeight: 300
                    implicitWidth: 300
                    radius: 4
                }
                Label {
                    Layout.alignment: Qt.AlignCenter
                    opacity: 0.6
                    font.pixelSize: 12
                    text: qsTrId('id_the_qr_code_does_not_include')
                    visible: self.context?.credentials?.bip39_passphrase ?? false
                }
                Bip39Passphrase {
                }
            }
        }
    }

    component Bip39Passphrase: RowLayout {
        Layout.alignment: Qt.AlignCenter
        Layout.fillWidth: false
        Layout.topMargin: 10
        spacing: 20
        visible: self.context?.credentials?.bip39_passphrase ?? false
        Image {
            source: 'qrc:/svg2/passphrase.svg'
        }
        Label {
            text: qsTrId('id_bip39_passphrase')
        }
        Label {
            color: '#2FD058'
            font.pixelSize : 14
            font.weight: 600
            text: self?.context.credentials?.bip39_passphrase ?? ''
        }
    }
}
