import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13

import './views'

Page {
    background: Rectangle {
        color: 'black'
        opacity: 0.2
    }

    header: ColumnLayout {
        Image {
            mipmap: true
            smooth: false
            source: 'assets/svg/logo_big.svg'
            sourceSize.height: 32

            Layout.alignment: Qt.AlignRight
            Layout.margins: 8
        }

        TextField {
            enabled: false
            placeholderText: qsTr('SEARCH')

            Layout.fillWidth: true
            Layout.margins: 8
        }
    }

    ScrollView {
        id: scroll_view
        clip: true
        anchors.fill: parent
        anchors.leftMargin: 8

        Column {
            spacing: 16

            WalletsSidebarItem {
                width: scroll_view.width
            }

            DevicesSidebarItem {
                width: scroll_view.width
            }
        }
    }

}
