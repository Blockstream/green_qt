import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Dialog {
    Overlay.modal: Rectangle {
        id: modal
        color: constants.c900
        FastBlur {
            anchors.fill: parent
            cached: true
            opacity: 0.5
            radius: 64 * self.opacity
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
    id: self
    anchors.centerIn: parent
    background: null
    modal: true
    closePolicy: Popup.NoAutoClose
    contentItem: ColumnLayout {
        Image {
            Layout.alignment: Qt.AlignCenter
            source: 'qrc:/svg2/fresh_wallet.svg'
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            Layout.maximumWidth: 250
            color: '#FFF'
            font.pixelSize: 18
            font.weight: 500
            horizontalAlignment: Label.AlignHCenter
            text: 'Congratulations and Welcome to your new Wallet'
            wrapMode: Label.WordWrap
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 10
            color: '#FFF'
            font.pixelSize: 14
            font.weight: 400
            horizontalAlignment: Label.AlignHCenter
            opacity: 0.6
            text: qsTrId('id_create_your_first_account_to')
        }
        PrimaryButton {
            Layout.topMargin: 25
            Layout.alignment: Qt.AlignCenter
            Layout.minimumWidth: 200
            text: qsTrId('id_create_account')
            onClicked: self.accept()
        }
    }
}
