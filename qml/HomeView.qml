import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

MainPage {
    readonly property string url: 'https://blockstream.com/green/'
    header: Pane {
        padding: 24
        background: Item {}
        contentItem: RowLayout {
            Label {
                text: 'Welcome back!'
                font.pixelSize: 24
                font.styleName: 'Medium'
            }
            Item {
                Layout.fillWidth: true
                height: 1
            }
            Button {
                text: 'id_support'
                opacity: 0
                flat: true
            }
        }
    }
    bottomPadding: 24
    contentItem: ColumnLayout {
        Item {
            width: 1
            Layout.fillHeight: true
        }
        Image {
            Layout.alignment: Qt.AlignHCenter
            source: 'qrc:/svg/green_logo.svg'
            sourceSize.height: 96
        }
        Item {
            width: 1
            Layout.fillHeight: true
        }
        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: qsTrId('Copyright (C)') + '<br/><br/>' +
                  qsTrId('id_version') + ' ' + Qt.application.version + '<br/><br/>' +
                  qsTrId('id_please_contribute_if_you_find') + ".<br/>" +
                  qsTrId('id_visit_s_for_further_information').arg(link(url)) + ".<br/><br/>" +
                  qsTrId('id_distributed_under_the_s_see').arg('GNU General Public License v3.0').arg(link('https://opensource.org/licenses/GPL-3.0'))
            textFormat: Text.RichText
            onLinkActivated: Qt.openUrlExternally(link)
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
            }
        }
    }
}
