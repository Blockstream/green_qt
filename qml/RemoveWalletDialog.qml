import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS

AbstractDialog {
    signal removeWallet(Wallet wallet)
    required property Wallet wallet
    property bool remove: false
    property var code: []
    function update() {
        const code = []
        for (let i = 0; i < 6; i++) {
            code.push(Math.floor(Math.random() * 10))
        }
        self.code = code
    }
    function check(code) {
        self.remove = self.code.join('') === code
        if (self.remove) {
            self.close()
        } else {
            self.update()
            pin_field.clear()
        }
    }
    Component.onCompleted: self.update()
    onClosed: {
        if (self.remove) {
            self.removeWallet(self.wallet)
        }
        self.destroy()
    }
    id: self
    header: null
    contentItem: StackViewPage {
        focus: true
        title: qsTrId('id_remove_wallet')
        rightItem: CloseButton {
            onClicked: self.close()
        }
        contentItem: ColumnLayout {
            spacing: 10
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.bottomMargin: 40
                font.pixelSize: 20
                font.weight: 600
                horizontalAlignment: Label.AlignHCenter
                text: self.wallet?.name ?? ''
                wrapMode: Label.Wrap
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                text: 'Enter the code to confirm'
            }
            RowLayout {
                HSpacer {
                }
                Repeater {
                    model: self.code
                    Label {
                        Layout.alignment: Qt.AlignCenter
                        font.pixelSize: 26
                        font.weight: 600
                        text: modelData
                    }
                }
                HSpacer {
                }
            }
            PinField {
                Layout.alignment: Qt.AlignCenter
                id: pin_field
                focus: true
                onPinEntered: (code) => self.check(code)
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                Layout.topMargin: 40
                source: 'qrc:/svg2/warning.svg'
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.bottomMargin: 40
                text: qsTrId('id_backup_your_mnemonic_before')
            }
        }
    }
    AnalyticsView {
        active: true
        name: 'DeleteWallet'
    }
}
