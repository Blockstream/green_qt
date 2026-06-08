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
        Layout.alignment: Qt.AlignHCenter
        spacing: 15
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            Image {
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.horizontalCenterOffset: -14
                source: 'qrc:/svg3/Jade.svg'
                fillMode: Image.PreserveAspectFit
                sourceSize: Qt.size(82, 113)
                height: 120
                width: height * 82 / 113
            }
        }
        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
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
    RegularButton {
        Layout.fillWidth: true
        text: qsTrId('id_jade_already_unlocked')
        onClicked: self.alreadyUnlocked()
    }
    PrimaryButton {
        Layout.fillWidth: true
        text: qsTrId('id_qr_pin_unlock')
        onClicked: self.unlockRequested()
    }
}
