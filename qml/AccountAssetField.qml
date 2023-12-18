import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

AbstractButton {
    property Account account
    property Asset asset
    property bool readonly: false

    id: self
    padding: 20
    background: Rectangle {
        radius: 5
        color: '#222226'
        Rectangle {
            border.width: 2
            border.color: '#00B45A'
            color: 'transparent'
            radius: 9
            anchors.fill: parent
            anchors.margins: -4
            opacity: self.visualFocus ? 1 : 0
        }
    }
    contentItem: RowLayout {
        spacing: 10
        Image {
            Layout.alignment: Qt.AlignCenter
            Layout.maximumWidth: 32
            Layout.maximumHeight: 32
            source: UtilJS.iconFor(self.asset || self.account)
        }
        ColumnLayout {
            Layout.alignment: Qt.AlignCenter
            Layout.fillHeight: false
            spacing: 0
            Label {
                font.pixelSize: 16
                font.weight: 600
                text: self.asset?.name ?? self.account?.network?.displayName ?? '-'
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.topMargin: 4
                font.capitalization: Font.AllUppercase
                font.pixelSize: 12
                font.weight: 500
                opacity: 0.4
                text: UtilJS.accountName(self.account)
                wrapMode: Label.Wrap
            }
            Label {
                font.capitalization: Font.AllUppercase
                font.pixelSize: 11
                font.weight: 400
                opacity: 0.4
                text: UtilJS.networkLabel(self.account?.network) + ' / ' + UtilJS.accountLabel(self.account)
            }
        }
        Image {
            Layout.alignment: Qt.AlignCenter
            source: 'qrc:/svg2/edit.svg'
            visible: !self.readonly
        }
    }
}
