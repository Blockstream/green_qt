import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    required property JadeGetMasterBlindingKeyActivity activity
    Connections {
        target: self.activity
        function onFinished() {
            self.StackView.view.pop()
        }
    }

    id: self
    spacing: 10
    VSpacer {
    }
    MultiImage {
        Layout.alignment: Qt.AlignCenter
        foreground: 'qrc:/svg3/Authenticator.svg'
        width: 352
        height: 240
    }
    Label {
        Layout.alignment: Qt.AlignCenter
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        Layout.maximumWidth: 300
        font.pixelSize: 16
        font.weight: 790
        horizontalAlignment: Label.AlignHCenter
        wrapMode: Label.WordWrap
        text: 'Green needs the master blinding key from Jade'
    }
    Label {
        Layout.alignment: Qt.AlignCenter
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        Layout.maximumWidth: 300
        horizontalAlignment: Label.AlignHCenter
        opacity: 0.6
        wrapMode: Label.WordWrap
        text: 'to show balances and transactions on Liquid accounts up to 10x faster at every login, and it\'s necessary to use Liquid singlesig accounts.'
    }
    PrimaryButton {
        Layout.bottomMargin: 20
        Layout.topMargin: 20
        Layout.alignment: Qt.AlignCenter
        Layout.minimumWidth: 200
        font.pixelSize: 14
        font.weight: 400
        text: qsTrId('id_continue')
        onClicked: {
            enabled = false
            busy = true
            self.activity.confirm()
        }
    }
    LinkButton {
        Layout.alignment: Qt.AlignCenter
        Layout.topMargin: 40
        text: qsTrId('id_learn_more')
        onClicked: Qt.openUrlExternally('https://help.blockstream.com/hc/en-us/articles/4403675941017-What-are-the-implications-of-exporting-the-master-blinding-key')
    }
    VSpacer {
    }
}
