import QtQuick 2.0
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

Column {
    FlatButton {
        anchors.horizontalCenter: parent.horizontalCenter
        text: qsTr('id_log_in')
        onClicked: wallet.connect()
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter

        CheckBox {
            id: proxy_checkbox
            text: qsTr('id_connect_through_a_proxy')
        }

        ColumnLayout {
            clip: true
            height: proxy_checkbox.checked ? implicitHeight : 0
            anchors.horizontalCenter: parent.horizontalCenter

            Behavior on height {
                SmoothedAnimation { }
            }

            TextField {
                id: proxy_host_field
                enabled: proxy_checkbox.checked
                placeholderText: qsTr('id_socks5_hostname')
            }

            TextField {
                id: proxy_port_field
                enabled: proxy_checkbox.checked
                placeholderText: qsTr('id_socks5_port')
            }
        }

        CheckBox {
            id: tor_checkbox
            text: qsTr('id_connect_with_tor')
            checked: true
        }
    }
}
