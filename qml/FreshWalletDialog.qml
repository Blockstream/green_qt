import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

Dialog {
    Overlay.modal: MultiEffect {
        anchors.fill: parent
        autoPaddingEnabled: false
        brightness: self.visible ? -0.05 : 0
        blurEnabled: true
        blurMax: 64
        blur: self.visible ? 1 : 0
        source: ApplicationWindow.contentItem
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
            text: 'Congratulations and welcome to your new wallet'
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
