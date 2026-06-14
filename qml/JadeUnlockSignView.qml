import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: self
    signal alreadyUnlocked()
    signal unlockRequested()

    spacing: 15
    ColumnLayout {
        Layout.fillWidth: true
        Layout.maximumWidth: 360
        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
        spacing: 15
        Item {
            Layout.alignment: Qt.AlignHCenter
            width: jade_image.width
            height: jade_image.height
            Image {
                id: jade_image
                anchors.centerIn: parent
                antialiasing: true
                fillMode: Image.PreserveAspectFit
                height: 190
                width: 88
                mipmap: true
                smooth: true
                source: 'qrc:/svg3/Jade.svg'
                sourceSize: Qt.size(width, height)
            }
        }
        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            Layout.topMargin: 10
            font.pixelSize: 18
            font.weight: 700
            horizontalAlignment: Label.AlignHCenter
            text: qsTr('Jade QR Mode')
            wrapMode: Label.WordWrap
        }
        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            font.pixelSize: 12
            font.weight: 400
            horizontalAlignment: Label.AlignHCenter
            opacity: 0.6
            text: qsTrId('id_unlock_jade_before_signing_the')
            wrapMode: Label.WordWrap
        }
    }
    VSpacer {
    }
    PrimaryButton {
        Layout.fillWidth: true
        text: qsTrId('id_qr_pin_unlock')
        onClicked: self.unlockRequested()
    }
    LinkButton {
        Layout.alignment: Qt.AlignCenter
        Layout.topMargin: 5
        text: qsTrId('id_jade_already_unlocked')
        onClicked: self.alreadyUnlocked()
    }
}
