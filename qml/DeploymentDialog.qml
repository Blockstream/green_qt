import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

Dialog {
    signal deploymentSelected(string deployment)
    signal cancel()
    onClosed: self.destroy()
    id: self
    closePolicy: Popup.NoAutoClose
    modal: true
    x: parent.width / 2 - self.implicitWidth / 2
    y: parent.height - self.implicitHeight - 60
    topPadding: 20
    bottomPadding: 20
    leftPadding: 20
    rightPadding: 20
    Overlay.modal: MultiEffect {
        anchors.fill: parent
        autoPaddingEnabled: false
        brightness: self.visible ? -0.05 : 0
        Behavior on brightness {
            NumberAnimation { duration: 200 }
        }
        blurEnabled: true
        blurMax: 64
        blur: self.visible ? 1 : 0
        Behavior on blur {
            NumberAnimation { duration: 200 }
        }
        source: ApplicationWindow.contentItem
    }
    background: Rectangle {
        anchors.fill: parent
        radius: 10
        color: '#13161D'
        border.width: 0.5
        border.color: Qt.lighter('#13161D')
    }
    contentItem: ColumnLayout {
        spacing: 10
        PrimaryButton {
            Layout.alignment: Qt.AlignCenter
            Layout.minimumWidth: 325
            focus: true
            text: 'Mainnet'
            onClicked: {
                self.close()
                self.deploymentSelected('mainnet')
            }
        }
        RegularButton {
            Layout.alignment: Qt.AlignCenter
            Layout.minimumWidth: 325
            icon.source: 'qrc:/svg2/flask.svg'
            text: 'Testnet'
            onClicked: {
                self.close()
                self.deploymentSelected('testnet')
            }
        }
        RegularButton {
            Layout.alignment: Qt.AlignCenter
            Layout.minimumWidth: 325
            text: qsTrId('id_cancel')
            onClicked: {
                self.close()
                self.cancel()
            }
        }
    }
}
