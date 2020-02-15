import QtQuick 2.0
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

Column {
    FlatButton {
        anchors.horizontalCenter: parent.horizontalCenter
        text: qsTr('id_log_in')
        onClicked: {
            const proxy = proxy_checkbox.checked ? proxy_host_field.text+':'+proxy_port_field.text : '';
            wallet.connect(proxy, use_tor_checkbox.checked);
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter

        CheckBox {
            id: proxy_checkbox
            text: qsTr('id_connect_through_a_proxy')
            checked: wallet.proxy.length > 0
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
                text: wallet.proxy.length > 0 ? wallet.proxy.split(':')[0] : ''
            }

            TextField {
                id: proxy_port_field
                enabled: proxy_checkbox.checked
                placeholderText: qsTr('id_socks5_port')
                text: wallet.proxy.length > 0 ? wallet.proxy.split(':')[1] : ''
            }
        }

        CheckBox {
            id: use_tor_checkbox
            text: qsTr('id_connect_with_tor')
            checked: wallet.useTor
        }
    }
}
