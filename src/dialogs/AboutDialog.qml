import QtQuick 2.0
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.13

Dialog {
    title: qsTr('id_about') // FIXME about string is uppercase
    width: 600
    height: 400

    anchors.centerIn: parent
    standardButtons: Dialog.Ok
    Material.accent: Material.Green
    Material.theme: Material.Dark

    Page {
        anchors.fill: parent
        anchors.centerIn: parent
        background: Item {}

        header: RowLayout {
            Image {
                Layout.margins: 16
                source: "../ic_home.png"
            }
        }
        // FIXME fix copyright, maybe add platform? (32 bit/64 bit)
        // FIXME add version (probably in green.pro?) since Qt.application.version is not working
        // FIXME add localized string
        Label {
            font.family: dinpro.name
            anchors.fill: parent
            anchors.margins: 16
            wrapMode: Text.WordWrap
            text: qsTr("Version Green %1

Copyright (C)

Please contribute if you find Green QT useful. Visit https://blockstream.com/green for further information about the software.
The source code is available from https://github.com/green/green_qt.

Distributed under the GNU General Public License v3.0, see LICENSE for more information or https://opensource.org/licenses/GPL-3.0"
                       .arg(Qt.application.version))
            color: 'white'
        }
    }
}
