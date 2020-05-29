import QtQuick 2.0
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.13

Dialog {
    title: qsTrId('id_about')
    width: 600
    height: 400

    anchors.centerIn: parent
    standardButtons: Dialog.Ok
    Material.accent: Material.Green
    Material.theme: Material.Dark

    header: RowLayout {
        Image {
            Layout.margins: 16
            source: 'qrc:/png/ic_home.png'
            sourceSize.height: 64
            fillMode: Image.PreserveAspectFit
            horizontalAlignment: Image.AlignLeft
        }
    }


    // FIXME fix copyright, maybe add platform? (32 bit/64 bit)
    Label {
        anchors.fill: parent
        wrapMode: Text.WordWrap
        text: qsTrId("Copyright (C)") + "\n\n" +
              qsTrId('id_version') + ' ' + Qt.application.version + '\n\n' +
              qsTrId('id_please_contribute_if_you_find') + ". " + qsTrId('id_visit_s_for_further_information').arg('https://github.com/Blockstream/green_qt') + ".\n\n"
              + qsTrId('id_distributed_under_the_s_see').arg('GNU General Public License v3.0').arg('https://opensource.org/licenses/GPL-3.0')
        color: 'white'
    }
}
