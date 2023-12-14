import Blockstream.Green.Core
import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractDialog {
    id: self
    title: qsTrId('id_app_settings')

    readonly property int labelWidth: Math.max(300, Math.floor(layout.width / 3))

    AnalyticsView {
        name: 'AppSettings'
        active: navigation.param.view === 'preferences'
    }
    clip: true
    width: 600
    height: 700
    header: null

    component Field: Pane {
        default property alias contentItemData: layout.data
        property alias icon: image.source
        property alias name: label.text
        Layout.fillWidth: true
        background: null
        padding: 0
        contentItem: RowLayout {
            spacing: 12
            Image {
                Layout.alignment: Qt.AlignTop
                Layout.minimumWidth: 16
                Layout.minimumHeight: 36
                id: image
                smooth: true
                mipmap: true
                fillMode: Image.Pad
                horizontalAlignment: Image.AlignHCenter
                verticalAlignment: Image.AlignVCenter
                sourceSize.height: 16
                sourceSize.width: 16
            }
            Label {
                id: label
                Layout.minimumWidth: self.labelWidth
                Layout.maximumWidth: self.labelWidth
                Layout.minimumHeight: 36
                Layout.alignment: Qt.AlignTop
                verticalAlignment: Text.AlignVCenter
            }
            Pane {
                Layout.fillWidth: true
                padding: 0
                background: null
                contentItem: RowLayout {
                    id: layout
                    spacing: 8
                }
            }
        }
    }
    component Separator: Item {
        implicitHeight: 24
        Layout.fillWidth: true
    }

    contentItem: GFlickable {
        id: flickable
        clip: true
        contentHeight: layout.height

        ColumnLayout {
            id: layout
            width: Math.min(flickable.availableWidth, 1024) - 16
            x: 8
            spacing: 4
            SectionLabel {
                text: qsTrId('id_general')
            }
            Field {
                name: qsTrId('id_language')
                GComboBox {
                    id: control
                    Layout.fillWidth: true
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
                    popup.contentItem.implicitHeight: 300
                }
            }
            Field {
                name: qsTrId('Show Blockstream News')
                GSwitch {
                    checked: Settings.showNews
                    onToggled: Settings.showNews = checked
                }
            }
            Field {
                name: qsTrId('id_enable_testnet')
                GSwitch {
                    checked: Settings.enableTestnet
                    onToggled: Settings.enableTestnet = checked
                }
            }
            Field {
                name: qsTrId('id_help_green_improve')
                GSwitch {
                    enabled: !Analytics.busy
                    checked: Settings.analytics === 'enabled'
                    onToggled: Settings.analytics = checked ? 'enabled' : 'disabled'
                }
                HSpacer {
                }
            }
            Separator {
            }
            SectionLabel {
                text: qsTrId('id_network')
            }
            Field {
                name: qsTrId('id_connect_through_a_proxy')
                icon: 'qrc:/svg/proxyV2.svg'
                GSwitch {
                    checked: Settings.useProxy
                    onToggled: Settings.useProxy = checked
                }
            }
            Field {
                name: qsTrId('id_proxy_host')
                enabled: Settings.useProxy
                visible: Settings.useProxy
                GTextField {
                    Layout.fillWidth: true
                    enabled: Settings.useProxy
                    text: Settings.proxyHost
                    onEditingFinished: {
                        console.log('update proxy host', text)
                        Settings.proxyHost = text
                    }
                }
            }
            Field {
                name: qsTrId('id_proxy_port')
                enabled: Settings.useProxy
                visible: Settings.useProxy
                GTextField {
                    enabled: Settings.useProxy
                    text: Settings.proxyPort
                    onEditingFinished: {
                        console.log('update proxy port', text)
                        Settings.proxyPort = text
                    }
                }
            }
            Field {
                name: qsTrId('id_connect_with_tor')
                icon: 'qrc:/svg/torV2.svg'
                GSwitch {
                    checked: Settings.useTor
                    onToggled: Settings.useTor = checked
                }
            }
            Separator {
            }
            SectionLabel {
                text: qsTrId('id_custom_servers_and_validation')
            }
            Field {
                name: qsTrId('id_personal_electrum_server')
                icon: 'qrc:/svg/electrum.svg'
                ColumnLayout {
                    spacing: 8
                    GSwitch {
                        Layout.fillWidth: true
                        text: qsTrId('id_choose_the_electrum_servers_you')
                        checked: Settings.usePersonalNode
                        onToggled: Settings.usePersonalNode = checked
                    }
                    GridLayout {
                        visible: Settings.usePersonalNode
                        columns: 2
                        columnSpacing: 16
                        rowSpacing: 8
                        Label {
                            Layout.minimumWidth: parent.width * 0.4
                            text: qsTrId('id_bitcoin_electrum_server')
                        }
                        GTextField {
                            Layout.fillWidth: true
                            text: Settings.bitcoinElectrumUrl
                            onTextChanged: Settings.bitcoinElectrumUrl = text
                            placeholderText: NetworkManager.network("electrum-mainnet").data.electrum_url
                        }
                        Label {
                            visible: Settings.enableTestnet
                            text: qsTrId('id_testnet_electrum_server')
                        }
                        GTextField {
                            Layout.fillWidth: true
                            visible: Settings.enableTestnet
                            text: Settings.testnetElectrumUrl
                            onTextChanged: Settings.testnetElectrumUrl = text
                            placeholderText: NetworkManager.network("electrum-testnet").data.electrum_url
                        }
                        Label {
                            text: qsTrId('id_liquid_electrum_server')
                        }
                        GTextField {
                            Layout.fillWidth: true
                            text: Settings.liquidElectrumUrl
                            onTextChanged: Settings.liquidElectrumUrl = text
                            placeholderText: NetworkManager.network("electrum-liquid").data.electrum_url
                        }
                        Label {
                            visible: Settings.enableTestnet
                            text: qsTrId('id_liquid_testnet_electrum_server')
                        }
                        GTextField {
                            Layout.fillWidth: true
                            visible: Settings.enableTestnet
                            text: Settings.liquidTestnetElectrumUrl
                            onTextChanged: Settings.liquidTestnetElectrumUrl = text
                            placeholderText: NetworkManager.network("electrum-testnet-liquid").data.electrum_url
                        }
                    }
                }
            }
            Field {
                name: qsTrId('id_spv_verification')
                icon: 'qrc:/svg/tx-check.svg'
                GSwitch {
                    Layout.fillWidth: true
                    text: qsTrId('id_verify_your_bitcoin')
                    checked: Settings.enableSPV
                    onToggled: Settings.enableSPV = checked
                }
            }
            Separator {
            }
            SectionLabel {
                text: qsTrId('id_advanced')
            }
            Field {
                name: qsTrId('id_enable_experimental_features')
                GSwitch {
                    checked: Settings.enableExperimental
                    onToggled: Settings.enableExperimental = checked
                }
            }
            Separator {
            }
            SectionLabel {
                text: qsTrId('id_support')
            }
            Field {
                name: qsTrId('id_data_directory')
                CopyableLabel {
                    Layout.fillWidth: true
                    text: data_location_path
                    copyText: data_location_path.replace(' ', '\\ ')
                    elide: Text.ElideRight
                }
                GButton {
                    text: qsTrId('id_open')
                    onClicked: Qt.openUrlExternally(data_location_url)
                }
            }
            Field {
                name: qsTrId('id_log_file')
                CopyableLabel {
                    Layout.fillWidth: true
                    text: log_file_path
                    copyText: log_file_path.replace(' ', '\\ ')
                    elide: Text.ElideRight
                }
                GButton {
                    text: qsTrId('id_open')
                    onClicked: Qt.openUrlExternally(log_file_url)
                }
            }
        }
    }
}
