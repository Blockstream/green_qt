import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

MainPage {
    readonly property string url: 'https://blockstream.com/green/'
    header: Pane {
        padding: 32
        background: Item {}
        contentItem: RowLayout {
            spacing: 16
            Image {
                source: 'qrc:/svg/green_logo.svg'
                sourceSize.height: 48
            }
            Item {
                Layout.fillWidth: true
                height: 1
            }
            Button {
                id: support_button
                readonly property string supportUrl: 'https://docs.blockstream.com/green/support.html'
                flat: true
                text: qsTrId('id_support')
                onClicked: Qt.openUrlExternally(supportUrl)
                ToolTip.text: supportUrl
                ToolTip.visible: support_button.hovered
            }
        }
    }
    contentItem: ColumnLayout {
        SectionLabel {
            visible: false
            leftPadding: 16
            text: 'Quick actions'
        }
        Row {
            visible: false
            padding: 16
            spacing: 16
            Button {
                text: 'Liquid Signup'
                onClicked: pushLocation('/liquid/signup')
                flat: true
            }
            Button {
                text: 'Liquid Restore'
                onClicked: pushLocation('/liquid/restore')
                flat: true
            }
        }
        SectionLabel {
            text: 'About'
        }
        // FIXME fix copyright, maybe add platform? (32 bit/64 bit)
        Label {
            //color: 'white'
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: qsTrId('Copyright (C)') + '<br/><br/>' +
                  qsTrId('id_version') + ' ' + Qt.application.version + '<br/><br/>' +
                  qsTrId('id_please_contribute_if_you_find') + ".<br/>" +
                  qsTrId('id_visit_s_for_further_information').arg(`<a href="${url}">${url}</a>`) + ".<br/><br/>" +
                  qsTrId('id_distributed_under_the_s_see').arg('GNU General Public License v3.0').arg('<a href="https://opensource.org/licenses/GPL-3.0">https://opensource.org/licenses/GPL-3.0</a>')
            textFormat: Text.RichText
            onLinkActivated: Qt.openUrlExternally(link)
        }
        Item {
            width: 1
            Layout.fillHeight: true
        }
    }
}
