import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.13

MainPage {
    id: self
    title: qsTrId('id_settings')

    header: MainPageHeader {
        contentItem: RowLayout {
            Label {
                text: self.title
                font.pixelSize: 24
                font.family: 'Roboto'
                font.styleName: 'Thin'
            }
            Item {
                Layout.fillWidth: true
                height: 1
            }
        }
    }
    component HSpacer: Item {
        Layout.fillWidth: true
        implicitHeight: 1
    }
    contentItem: ScrollView {
        id: scroll_view
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        contentWidth: availableWidth
        ColumnLayout {
            width: parent.width
            spacing: 16
            MainPage.Section {
                Layout.fillWidth: true
                title: qsTrId('General')
                contentItem: GridLayout {
                    columns: 3
                    columnSpacing: 16
                    rowSpacing: 8
                    Label {
                        text: 'Collapse Side Bar'
                    }
                    Switch {
                        checked: Settings.collapseSideBar
                        onCheckedChanged: Settings.collapseSideBar = checked
                    }
                    HSpacer {
                    }
                    Label {
                        text: qsTrId('Enable testnet')
                    }
                    Switch {
                        id: testnet_switch
                        checked: Settings.enableTestnet
                        onCheckedChanged: Settings.enableTestnet = checked
                    }
                    HSpacer {
                    }
                }
            }
            MainPage.Section {
                Layout.fillWidth: true
                title: qsTrId('id_network')
                contentItem: GridLayout {
                    columns: 3
                    columnSpacing: 16
                    rowSpacing: 8
                    Label {
                        text: qsTrId('id_connect_through_a_proxy')
                    }
                    Switch {
                        id: proxy_switch
                        checked: Settings.useProxy
                        onCheckedChanged: Settings.useProxy = checked
                    }
                    HSpacer {
                    }
                    Label {
                        text: qsTrId('Proxy host')
                        enabled: proxy_switch.checked
                    }
                    TextField {
                        id: proxy_host_field
                        enabled: Settings.useProxy
                        Layout.alignment: Qt.AlignLeft
                        Layout.minimumWidth: 200
                        text: Settings.proxyHost
                        onTextChanged: Settings.proxyHost = text
                    }
                    HSpacer {
                    }
                    Label {
                        text: qsTrId('Proxy port')
                        enabled: proxy_switch.checked
                    }
                    TextField {
                        id: proxy_port_field
                        enabled: Settings.useProxy
                        Layout.alignment: Qt.AlignLeft
                        Layout.maximumWidth: 60
                        text: Settings.proxyPort
                        onTextChanged: Settings.proxyPort = text
                    }
                    HSpacer {
                    }
                    Label {
                        text: qsTrId('id_connect_with_tor')
                    }
                    Switch {
                        id: tor_switch
                        Layout.alignment: Qt.AlignLeft
                        checked: Settings.useTor
                        onCheckedChanged: Settings.useTor = checked
                    }
                    HSpacer {
                    }
                }
            }
        }
    }
}
