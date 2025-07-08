import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Pane {
    signal createAccountClicked
    id: self
    background: null
    contentItem: ColumnLayout {
        VSpacer {
        }
        Image {
            Layout.alignment: Qt.AlignCenter
            Layout.preferredHeight: 184
            antialiasing: true
            fillMode: Image.PreserveAspectFit
            mipmap: true
            smooth: true
            source: 'qrc:/svg3/Wallet.svg'
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
            text: qsTrId('id_welcome_to_your_wallet')
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
            onClicked: self.createAccountClicked()
        }
        VSpacer {
        }
    }
}
