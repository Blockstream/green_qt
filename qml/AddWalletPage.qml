import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    signal newWallet()
    signal restoreWallet()
    signal watchOnlyWallet()
    id: self
    padding: 60
    contentItem: ColumnLayout {
        spacing: 0
        VSpacer {
        }
        Image {
            Layout.alignment: Qt.AlignCenter
            Layout.maximumHeight: self.height / 4
            fillMode: Image.PreserveAspectFit
            horizontalAlignment: Image.AlignHCenter
            source: 'qrc:/svg2/take_control.svg'
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 20
            color: '#FFF'
            font.family: 'SF Compact'
            font.pixelSize: 35
            font.weight: 656
            horizontalAlignment: Label.AlignHCenter
            text: 'Take Control: Your Keys, Your Bitcoin'
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 10
            color: '#FFF'
            font.family: 'SF Compact Display'
            font.pixelSize: 22
            font.weight: 400
            horizontalAlignment: Label.AlignHCenter
            opacity: 0.6
            text: qsTrId('id_everything_you_need_to_take')
        }
        PrimaryButton {
            Layout.alignment: Qt.AlignCenter
            Layout.minimumWidth: 325
            Layout.topMargin: 80
            text: qsTrId('id_new_wallet')
            onClicked: self.newWallet()
        }
        PrimaryButton {
            Layout.alignment: Qt.AlignCenter
            Layout.minimumWidth: 325
            Layout.topMargin: 10
            text: qsTrId('id_restore_wallet')
            onClicked: self.restoreWallet()
        }
        RegularButton {
            Layout.alignment: Qt.AlignCenter
            Layout.minimumWidth: 325
            Layout.topMargin: 10
            text: qsTrId('id_watchonly')
            onClicked: self.watchOnlyWallet()
        }
        VSpacer {
        }
    }
}
