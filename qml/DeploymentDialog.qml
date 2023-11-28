import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

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
    Overlay.modal: Rectangle {
        id: modal
        color: constants.c900
        FastBlur {
            anchors.fill: parent
            cached: true
            opacity: 0.5
            radius: 32
            source: ShaderEffectSource {
                sourceItem: ApplicationWindow.contentItem
                sourceRect {
                    x: 0
                    y: 0
                    width: modal.width
                    height: modal.height
                }
            }
        }
    }
    background: Item {
        DropShadow {
            opacity: 0.5
            verticalOffset: 8
            radius: 32
            samples: 16
            source: r
            anchors.fill: r
        }
        Rectangle {
            id: r
            anchors.fill: parent
            radius: 10
            color: '#13161D'
            border.width: 0.5
            border.color: Qt.lighter('#13161D')
        }
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
