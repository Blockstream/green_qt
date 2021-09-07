import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.13

MainPage {
    id: self
    title: 'App Settings'

    header: MainPageHeader {
        contentItem: RowLayout {
            Label {
                text: self.title
                font.pixelSize: 24
                font.styleName: 'Medium'
            }
            HSpacer {}
            GButton {
                text: qsTrId('id_support')
                large: true
                highlighted: true
                onClicked: Qt.openUrlExternally(constants.supportUrl)
            }
        }
    }
    contentItem: ScrollView {
        id: scroll_view
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AlwaysOn
        clip: true
        focusPolicy: Qt.StrongFocus
        ColumnLayout {
            width: scroll_view.availableWidth
            spacing: 16
            MainPageSection {
                Layout.fillWidth: true
                title: qsTrId('id_general')
                contentItem: GridLayout {
                    columns: 3
                    columnSpacing: 16
                    rowSpacing: 8
                    Label {
                        text: qsTrId('id_language')
                    }
                    GComboBox {
                        id: control
                        Layout.minimumWidth: 400
                        model: languages
                        textRole: 'name'
                        valueRole: 'language'
                        currentIndex: {
                            for (let i = 0; i < languages.length; ++i) {
                                if (languages[i].language === Settings.language) return i;
                            }
                            return -1
                        }
                        onCurrentValueChanged: Settings.language = currentValue
                        font.capitalization: Font.Capitalize
                        delegate: ItemDelegate {
                            width: control.width
                            contentItem: Text {
                                text: modelData.name
                                color: 'white'
                                font: control.font
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }
                            highlighted: control.highlightedIndex === index
                        }
                    }
                    HSpacer {
                    }
                    Label {
                        text: qsTrId('Show Blockstrem News')
                    }
                    GSwitch {
                        checked: Settings.showNews
                        onCheckedChanged: Settings.showNews = checked
                    }
                    HSpacer {
                    }
                    Label {
                        text: qsTrId('id_collapse_side_bar')
                    }
                    GSwitch {
                        checked: Settings.collapseSideBar
                        onCheckedChanged: Settings.collapseSideBar = checked
                    }
                    HSpacer {
                    }
                    Label {
                        text: qsTrId('id_enable_testnet')
                    }
                    GSwitch {
                        checked: Settings.enableTestnet
                        onCheckedChanged: Settings.enableTestnet = checked
                    }
                    HSpacer {
                    }
                    Label {
                        text: qsTrId('id_check_for_updates_on_startup')
                    }
                    GSwitch {
                        checked: Settings.checkForUpdates
                        onCheckedChanged: Settings.checkForUpdates = checked
                    }
                }
            }
            MainPageSection {
                Layout.fillWidth: true
                title: qsTrId('id_network')
                contentItem: GridLayout {
                    columns: 3
                    columnSpacing: 16
                    rowSpacing: 8
                    Label {
                        text: qsTrId('id_connect_through_a_proxy')
                    }
                    GSwitch {
                        id: proxy_switch
                        checked: Settings.useProxy
                        onCheckedChanged: Settings.useProxy = checked
                    }
                    HSpacer {
                    }
                    Label {
                        text: qsTrId('id_proxy_host')
                        enabled: proxy_switch.checked
                    }
                    GTextField {
                        id: proxy_host_field
                        enabled: Settings.useProxy
                        Layout.alignment: Qt.AlignLeft
                        Layout.minimumWidth: 200
                        //text: Settings.proxyHost
                        onTextChanged: Settings.proxyHost = text
                    }
                    HSpacer {
                    }
                    Label {
                        text: qsTrId('id_proxy_port')
                        enabled: proxy_switch.checked
                    }
                    GTextField {
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
                    GSwitch {
                        id: tor_switch
                        Layout.alignment: Qt.AlignLeft
                        checked: Settings.useTor
                        onCheckedChanged: Settings.useTor = checked
                    }
                    HSpacer {
                    }
                }
            }
            MainPageSection {
                Layout.fillWidth: true
                title: qsTrId('id_support')
                contentItem: GridLayout {
                    columns: 5
                    columnSpacing: 16
                    rowSpacing: 8
                    Label {
                        text: qsTrId('id_data_directory')
                    }
                    Label {
                        text: data_location_path
                    }
                    GButton {
                        text: qsTrId('id_copy')
                        onClicked: {
                            Clipboard.copy(data_location_path);
                            ToolTip.show(qsTrId('id_copied_to_clipboard'), 1000);
                        }
                    }
                    GButton {
                        text: qsTrId('id_open')
                        onClicked: Qt.openUrlExternally(data_location_url)
                    }
                    HSpacer {
                    }
                    Label {
                        text: qsTrId('id_log_file')
                    }
                    Label {
                        text: log_file_path
                    }
                    GButton {
                        text: qsTrId('id_copy')
                        onClicked: {
                            Clipboard.copy(log_file_path);
                            ToolTip.show(qsTrId('id_copied_to_clipboard'), 1000);
                        }
                    }
                    GButton {
                        text: qsTrId('id_open')
                        onClicked: Qt.openUrlExternally(log_file_url)
                    }
                    HSpacer {
                    }
                }
            }
        }
    }
}
