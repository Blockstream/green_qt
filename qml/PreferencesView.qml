import Blockstream.Green.Core
import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractDialog {
    id: self

    AnalyticsView {
        name: 'AppSettings'
        active: true
    }
    clip: true
    width: 500
    height: 650
    header: null
    topPadding: 20
    bottomPadding: 40
    leftPadding: 40
    rightPadding: 40

    component Separator: Item {
        implicitHeight: 24
        Layout.fillWidth: true
    }

    contentItem: GStackView {
        id: stack_view
        initialItem: StackViewPage {
            title: qsTrId('id_app_settings')
            rightItem: CloseButton {
                onClicked: self.close()
            }
            contentItem: ColumnLayout {
                spacing: 10
                SubButton {
                    text: qsTrId('id_general')
                    onClicked: stack_view.push(general_page)
                }
                SubButton {
                    text: qsTrId('id_network')
                    onClicked: stack_view.push(network_page)
                }
                SubButton {
                    text: qsTrId('id_custom_servers_and_validation')
                    onClicked: stack_view.push(servers_validation_page)
                }
                SwitchButton {
                    text: qsTrId('id_help_green_improve')
                    checked: Settings.analytics === 'enabled'
                    onClicked: Settings.analytics = Settings.analytics === 'enabled' ? 'disabled' : 'enabled'
                }
                VSpacer {
                }
                SubButton {
                    text: qsTrId('id_support')
                    onClicked: stack_view.push(support_page)
                }
            }
        }
    }

    component BaseButton: AbstractButton {
        Layout.fillWidth: true
        id: button
        font.pixelSize: 14
        font.weight: 500
        leftPadding: 20
        rightPadding: 20
        topPadding: 20
        bottomPadding: 20
        opacity: button.enabled ? 1 : 0.6
        background: Rectangle {
            color: Qt.lighter( '#222226', button.enabled && button.hovered ? 1.2 : 1)
            radius: 5
        }
    }

    component FileButton: BaseButton {
        required property url url
        id: button
        hoverEnabled: false
        contentItem: RowLayout {
            spacing: 20
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: button.text
                elide: Label.ElideMiddle
            }
            CircleButton {
                hoverEnabled: true
                icon.source: 'qrc:/svg2/copy.svg'
                onClicked: Clipboard.copy(button.text)
            }
            ShareButton {
                hoverEnabled: true
                url: button.url
            }
        }
    }

    component VersionButton: BaseButton {
        hoverEnabled: false
        contentItem: RowLayout {
            spacing: 20
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: Qt.application.version
                elide: Label.ElideMiddle
            }
            CircleButton {
                hoverEnabled: true
                icon.source: 'qrc:/svg2/copy.svg'
                onClicked: Clipboard.copy(Qt.application.version)
            }
        }
    }

    component SubButton: BaseButton {
        id: button
        contentItem: RowLayout {
            Label {
                Layout.fillWidth: true
                text: button.text
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                Layout.leftMargin: 10
                source: 'qrc:/svg2/right.svg'
            }
        }
    }

    component SelectLanguageButton: BaseButton {
        contentItem: RowLayout {
            Label {
                Layout.fillWidth: true
                text: qsTrId('id_language')
            }
            Label {
                opacity: 0.6
                text: {
                    for (const { name, language } of languages) {
                        if (Settings.language === language) {
                            return name
                        }
                    }
                }
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                Layout.leftMargin: 10
                source: 'qrc:/svg2/right.svg'
            }
        }
    }

    component SwitchButton: BaseButton {
        id: button
        topPadding: 15
        bottomPadding: 15
        contentItem: RowLayout {
            spacing: 0
            Image {
                id: image
                Layout.preferredHeight: 24
                Layout.preferredWidth: 24
                Layout.rightMargin: 10
                source: button.icon.source
                visible: image.status === Image.Ready
            }
            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.rightMargin: 10
                font.pixelSize: 14
                font.weight: 500
                text: button.text
                wrapMode: Label.Wrap
            }
            GSwitch {
                enabled: false
                opacity: 1
                checked: button.checked
            }
        }
    }

    Component {
        id: general_page
        StackViewPage {
            title: qsTrId('id_general')
            rightItem: CloseButton {
                onClicked: self.close()
            }
            contentItem: ColumnLayout {
                SelectLanguageButton {
                    onClicked: stack_view.push(language_page)
                }
                SwitchButton {
                    text: qsTrId('id_enable_testnet')
                    checked: Settings.enableTestnet
                    onClicked: Settings.enableTestnet = !Settings.enableTestnet
                }
                SwitchButton {
                    text: qsTrId('id_enable_experimental_features')
                    checked: Settings.enableExperimental
                    onClicked: Settings.enableExperimental = !Settings.enableExperimental
                }
                SwitchButton {
                    text: qsTrId('id_remember_device_connection')
                    checked: Settings.rememberDevices
                    onClicked: Settings.toggleRememberDevices()
                }
                VSpacer {
                }
            }
        }
    }

    Component {
        id: language_page
        StackViewPage {
            title: qsTrId('id_language')
            rightItem: CloseButton {
                onClicked: self.close()
            }
            contentItem: TListView {
                model: languages
                spacing: 5
                delegate: BaseButton {
                    width: ListView.view.width
                    contentItem: RowLayout {
                        Label {
                            text: modelData.name
                        }
                        Image {
                            source: 'qrc:/svg2/check.svg'
                            visible: modelData.language === Settings.language
                        }
                    }
                    onClicked: {
                        Settings.language = modelData.language
                        stack_view.pop()
                    }
                }
            }
        }
    }

    Component {
        id: network_page
        StackViewPage {
            title: qsTrId('id_network')
            rightItem: CloseButton {
                onClicked: self.close()
            }
            contentItem: ColumnLayout {
                spacing: 10
                SectionLabel {
                    text: qsTrId('id_tor')
                }
                SwitchButton {
                    Layout.bottomMargin: 25
                    icon.source: 'qrc:/svg/torV2.svg'
                    text: qsTrId('id_connect_with_tor')
                    checked: Settings.useTor
                    onClicked: Settings.useTor = !Settings.useTor
                }
                SectionLabel {
                    text: qsTrId('Proxy')
                }
                SwitchButton {
                    icon.source: 'qrc:/svg/proxyV2.svg'
                    text: qsTrId('id_connect_through_a_proxy')
                    checked: Settings.useProxy
                    onClicked: Settings.useProxy = !Settings.useProxy
                }
                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 25
                    SectionLabel {
                        text: qsTrId('id_proxy_host')
                    }
                    SectionLabel {
                        text: qsTrId('id_proxy_port')
                    }
                    TTextField {
                        Layout.fillWidth: true
                        enabled: Settings.useProxy
                        text: Settings.proxyHost
                        onEditingFinished: {
                            Settings.proxyHost = text
                        }
                    }
                    TTextField {
                        enabled: Settings.useProxy
                        text: Settings.proxyPort
                        onEditingFinished: {
                            Settings.proxyPort = text
                        }
                    }
                }
                VSpacer {
                }
            }
        }
    }

    Component {
        id: servers_validation_page
        StackViewPage {
            title: qsTrId('id_custom_servers_and_validation')
            rightItem: CloseButton {
                onClicked: self.close()
            }
            contentItem: ColumnLayout {
                spacing: 2
                SectionLabel {
                    text: qsTrId('id_personal_electrum_server')
                }
                SwitchButton {
                    icon.source: 'qrc:/svg/electrum.svg'
                    text: qsTrId('id_choose_the_electrum_servers_you')
                    checked: Settings.usePersonalNode
                    onClicked: Settings.usePersonalNode = !Settings.usePersonalNode
                }
                Collapsible {
                    Layout.fillWidth: true
                    id: collapsible
                    animationVelocity: 600
                    collapsed: !Settings.usePersonalNode
                    ColumnLayout {
                        width: collapsible.width
                        spacing: 2
                        SectionLabel {
                            Layout.topMargin: 10
                            text: qsTrId('id_bitcoin_electrum_server')
                        }
                        TTextField {
                            Layout.fillWidth: true
                            enabled: Settings.usePersonalNode
                            text: Settings.bitcoinElectrumUrl
                            onTextChanged: Settings.bitcoinElectrumUrl = text
                        }
                        SectionLabel {
                            Layout.topMargin: 10
                            visible: Settings.enableTestnet
                            text: qsTrId('id_testnet_electrum_server')
                        }
                        TTextField {
                            Layout.fillWidth: true
                            enabled: Settings.usePersonalNode
                            visible: Settings.enableTestnet
                            text: Settings.testnetElectrumUrl
                            onTextChanged: Settings.testnetElectrumUrl = text
                        }
                        SectionLabel {
                            Layout.topMargin: 10
                            text: qsTrId('id_liquid_electrum_server')
                        }
                        TTextField {
                            Layout.fillWidth: true
                            enabled: Settings.usePersonalNode
                            text: Settings.liquidElectrumUrl
                            onTextChanged: Settings.liquidElectrumUrl = text
                        }
                        SectionLabel {
                            Layout.topMargin: 10
                            visible: Settings.enableTestnet
                            text: qsTrId('id_liquid_testnet_electrum_server')
                        }
                        TTextField {
                            Layout.fillWidth: true
                            enabled: Settings.usePersonalNode
                            visible: Settings.enableTestnet
                            text: Settings.liquidTestnetElectrumUrl
                            onTextChanged: Settings.liquidTestnetElectrumUrl = text
                        }
                        SwitchButton {
                            Layout.topMargin: 10
                            text: qsTrId('Enable TLS/SSL')
                            checked: Settings.enableElectrumTls
                            onClicked: Settings.enableElectrumTls = !Settings.enableElectrumTls
                        }
                    }
                }
                SectionLabel {
                    Layout.topMargin: 30
                    text: qsTrId('id_spv_verification')
                }
                SwitchButton {
                    icon.source: 'qrc:/svg/tx-check.svg'
                    text: qsTrId('id_verify_your_bitcoin')
                    checked: Settings.enableSPV
                    onClicked: Settings.enableSPV = !Settings.enableSPV
                }
                VSpacer {
                }
            }
        }
    }

    Component {
        id: support_page
        StackViewPage {
            id: page
            title: qsTrId('id_support')
            rightItem: CloseButton {
                onClicked: self.close()
            }
            contentItem: ColumnLayout {
                spacing: 10
                SectionLabel {
                    text: qsTrId('id_data_directory')
                }
                FileButton {
                    text: data_location_path
                    url: data_location_url
                }
                SectionLabel {
                    Layout.topMargin: 25
                    text: qsTrId('id_log_file')
                }
                FileButton {
                    text: log_file_path
                    url: log_file_url
                }
                SectionLabel {
                    Layout.topMargin: 25
                    text: qsTrId('id_version')
                }
                VersionButton {
                }
                VSpacer {
                }
                SubButton {
                    text: 'Give us your feedback'
                    onClicked: {
                        page.StackView.view.push(request_support_page, {
                            type: 'feedback',
                            subject: 'Feedback from green_qt'
                        })
                    }
                }
                SubButton {
                    text: 'Get Support'
                    onClicked: {
                        page.StackView.view.push(request_support_page, {
                            type: 'incident',
                            subject: 'Bug report from green_qt'
                        })
                    }
                }
            }
        }
    }
    Component {
        id: request_support_page
        RequestSupportPage {
            id: page
            onSubmitted: (request) => {
                page.StackView.view.replace(page, support_submitted_page, { request, type: page.type }, StackView.PushTransition)
            }
        }
    }

    Component {
        id: support_submitted_page
        SupportSubmittedPage {
        }
    }
}
