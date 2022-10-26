import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

MainPage {
    id: self
    property alias count: devices_list_view.count
    readonly property string url: 'https://help.blockstream.com/hc/en-us/categories/900000061906-Blockstream-Jade'

    function formatDeviceState(state) {
        switch (state) {
            case JadeDevice.StateLocked:
                return qsTrId('id_locked')
            case JadeDevice.StateTemporary:
            case JadeDevice.StateReady:
                return qsTrId('id_ready')
            case JadeDevice.StateUnsaved:
            case JadeDevice.StateUninitialized:
                return qsTrId('id_not_initialized')
            default:
                return qsTrId('id_unknown')
        }
    }

    JadeFirmwareController {
        id: firmware_controller
        enabled: Settings.checkForFirmwareUpdates
    }

    JadeDeviceSerialPortDiscoveryAgent {
    }
    DeviceListModel {
        id: device_list_model
        type: Device.BlockstreamJade
    }
    AnalyticsView {
        active: window.navigation.location === '/jade'
        name: 'DeviceList'
    }
    header: MainPageHeader {
        contentItem: RowLayout {
            spacing: 12
            Label {
                text: qsTrId('id_blockstream_devices')
                font.pixelSize: 24
                font.styleName: 'Medium'
            }
            Label {
                visible: self.count > 0
                text: self.count
                color: constants.c800
                font.pixelSize: 12
                font.styleName: 'Medium'
                horizontalAlignment: Label.AlignHCenter
                leftPadding: 6
                rightPadding: 6
                background: Rectangle {
                    color: 'white'
                    radius: 4
                }
            }
            HSpacer {
            }
            GButton {
                text: qsTrId('id_get_jade')
                visible: devices_list_view.count === 0
                highlighted: true
                large: true
                onClicked: Qt.openUrlExternally('https://store.blockstream.com/product/blockstream-jade/')
            }
        }
    }
    footer: StatusBar {
        contentItem: RowLayout {
            SessionBadge {
                session: HttpManager.session
            }
        }
    }
    contentItem: StackLayout {
        currentIndex: devices_list_view.count === 0 ? 0 : 1
        ColumnLayout {
            spacing: constants.s1
            VSpacer {
                Layout.fillWidth: true
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg/blockstream_jade.svg'
                sourceSize.height: 32
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                text: qsTrId('id_connect_your_jade_to_use_it')
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                text: qsTrId('id_need_help') + ' ' + link(url, qsTrId('id_visit_the_blockstream_help'))
                textFormat: Text.RichText
                color: 'white'
                onLinkActivated: Qt.openUrlExternally(url)
                background: MouseArea {
                    acceptedButtons: Qt.NoButton
                    cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                }
            }
            VSpacer {
            }
        }
        SplitView {
            focusPolicy: Qt.ClickFocus
            handle: Item {
                implicitWidth: 32
                implicitHeight: parent.height
            }
            GListView {
                SplitView.minimumWidth: 300
                id: devices_list_view
                clip: true
                model: device_list_model
                spacing: 0
                currentIndex: {
                    for (let i = 0; i < devices_list_view.count; ++i) {
                        if (devices_list_view.itemAtIndex(i).location === navigation.location) {
                            return i
                        }
                    }
                    return 0
                }
                delegate: Button {
                    id: self
                    required property JadeDevice device
                    readonly property string location: device ? '/jade/' + device.versionInfo.EFUSEMAC.slice(-6) : '/jade'
                    width: ListView.view.contentWidth
                    onClicked: navigation.go(location)
                    padding: 16
                    highlighted: ListView.isCurrentItem
                    background: Rectangle {
                        radius: 4
                        border.width: 1
                        color: self.highlighted ? constants.c700 : self.hovered ? constants.c700 : constants.c800
                        border.color: self.highlighted ? constants.g500 : constants.c700
                    }
                    contentItem: ColumnLayout {
                        spacing: 16
                        Label {
                            Layout.fillWidth: true
                            text: `Jade ${device.versionInfo.EFUSEMAC.slice(-6)}`
                            font.pixelSize: 16
                        }
                        RowLayout {
                            spacing: 16
                            Image {
                                Layout.preferredHeight: 24
                                Layout.preferredWidth: 24
                                source: 'qrc:/svg/usbAlt.svg'
                            }
                            Image {
                                Layout.alignment: Qt.AlignLeft
                                smooth: true
                                mipmap: true
                                fillMode: Image.PreserveAspectFit
                                horizontalAlignment: Image.AlignHCenter
                                verticalAlignment: Image.AlignVCenter
                                source: 'qrc:/svg/blockstream_jade.svg'
                                sourceSize.height: 24
                            }
                            HSpacer {
                            }
                            Label {
                                font.pixelSize: 10
                                font.capitalization: Font.AllUppercase
                                leftPadding: 8
                                rightPadding: 8
                                topPadding: 4
                                bottomPadding: 4
                                color: 'white'
                                background: Rectangle {
                                    color: constants.r500
                                    radius: 4
                                }
                                visible: device.versionInfo.JADE_FEATURES !== 'SB'
                                text: device.versionInfo.JADE_FEATURES
                            }
                            Label {
                                font.pixelSize: 10
                                font.capitalization: Font.AllUppercase
                                leftPadding: 8
                                rightPadding: 8
                                topPadding: 4
                                bottomPadding: 4
                                color: 'white'
                                background: Rectangle {
                                    color: constants.c400
                                    radius: 4
                                }
                                text: device ? formatDeviceState(device.state) : ''
                            }
                        }
                    }
                }
            }
            StackLayout {
                SplitView.fillWidth: true
                SplitView.minimumWidth: 600
                currentIndex: devices_list_view.currentIndex
                Repeater {
                    model: device_list_model
                    View {
                    }
                }
            }
        }
    }

    component NetworkSection: Pane {
        id: self
        property bool comingSoon
        property Network network
        property JadeDevice device
        Layout.fillWidth: true
        Layout.preferredHeight: 60
        enabled: controller.enabled
        background: Item {
            Rectangle {
                width: parent.width
                height: 1
                y: parent.height - 1
                color: constants.c600
            }
        }
        padding: 0
        bottomPadding: 8
        topPadding: 8
        JadeLoginController {
            id: controller
            device: comingSoon ? null : self.device
            network: self.network.id
            onInvalidPin: self.ToolTip.show(qsTrId('id_invalid_pin'), 2000);
            onLoginDone: Analytics.recordEvent('wallet_login', segmentationWalletLogin(controller.wallet, { method: 'hardware' }))
        }
        contentItem: RowLayout {
            spacing: constants.s1
            RowLayout {
                Layout.fillWidth: false
                Layout.minimumWidth: 150
                spacing: constants.s1
                Image {
                    source: iconFor(self.network)
                    sourceSize.width: 24
                    sourceSize.height: 24
                }
                Label {
                    Layout.fillWidth: true
                    text: self.network.displayName
                }
            }
            RowLayout {
                Layout.fillWidth: false
                Layout.minimumWidth: 150
                spacing: constants.s1
                Image {
                    fillMode: Image.PreserveAspectFit
                    sourceSize.height: 24
                    sourceSize.width: 24
                    source: self.network.electrum ? 'qrc:/svg/key.svg' : 'qrc:/svg/multi-sig.svg'
                }
                Label {
                    Layout.fillWidth: true
                    text: self.network.electrum ? qsTrId('id_singlesig') : qsTrId('id_multisig_shield')
                    ToolTip.delay: 300
                    ToolTip.visible: mouse_area.containsMouse
                    ToolTip.text: self.network.electrum
                          ? qsTrId('id_your_funds_are_secured_by_a')
                          : qsTrId('id_your_funds_are_secured_by')
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        id: mouse_area
                    }
                }
            }
            Label {
                Layout.fillWidth: true
                text: controller.wallet ? controller.wallet.name : ''
            }
            RowLayout {
                visible: !comingSoon
                Layout.fillWidth: false
                Layout.minimumWidth: 150
                GButton {
                    visible: !controller.wallet || controller.wallet.authentication !== Wallet.Authenticated
                    enabled: !controller.active
                    text: switch (device.state) {
                        case JadeDevice.StateReady:
                        case JadeDevice.StateTemporary:
                            return qsTrId('id_login')
                        case JadeDevice.StateLocked:
                            return qsTrId('id_unlock')
                        default:
                            return qsTrId('id_setup_jade')
                    }
                    onClicked: controller.active = true
                }
                GButton {
                    visible: controller.wallet && controller.wallet.authentication === Wallet.Authenticated
                    text: qsTrId('id_go_to_wallet')
                    onClicked: navigation.go(`/${self.network.key}/${controller.wallet.id}`)
                }
            }
            RowLayout {
                visible: comingSoon
                Layout.fillWidth: false
                Layout.minimumWidth: 150
                Label {
                    background: Rectangle {
                        color: 'yellow'
                        radius: height / 2
                    }
                    color: 'black'
                    leftPadding: 8
                    rightPadding: 8
                    topPadding: 2
                    bottomPadding: 2
                    text: qsTrId('id_coming_soon')
                    font.pixelSize: 10
                    font.styleName: 'Medium'
                    font.capitalization: Font.AllUppercase
                }
            }
        }
    }

    component View: ColumnLayout {
        id: self
        required property JadeDevice device
        spacing: constants.s3
        Layout.minimumWidth: implicitWidth

        JadeUpdateDialog {
            id: update_dialog
            device: self.device
        }

        Page {
            Layout.alignment: Qt.AlignTop
            Layout.minimumWidth: implicitWidth
            Layout.fillWidth: true
            background: null
            header: Label {
                text: qsTrId('id_details')
                font.pixelSize: 20
                font.styleName: 'Bold'
                bottomPadding: constants.s1
            }
            contentItem: GridLayout {
                columns: 2
                columnSpacing: constants.s2
                rowSpacing: constants.s1
                Label {
                    text: qsTrId('id_networks')
                }
                Label {
                    text: {
                        const nets = self.device.versionInfo.JADE_NETWORKS
                        if (nets === 'ALL') return qsTrId('id_all_networks')
                        if (nets === 'TEST') return qsTrId('id_bitcoin_testnet_and_liquid')
                        if (nets === 'MAIN') return qsTrId('id_bitcoin_and_liquid')
                    }
                }
                Label {
                    text: qsTrId('id_system_location')
                }
                Label {
                    text: device.systemLocation
                }
            }
        }
        Page {
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            Layout.minimumWidth: implicitWidth
            background: null
            header: Label {
                text: qsTrId('id_firmware')
                font.pixelSize: 20
                font.styleName: 'Bold'
                bottomPadding: constants.s1
            }
            contentItem: GridLayout {
                columns: 2
                columnSpacing: constants.s2
                rowSpacing: constants.s0
                Label {
                    Layout.minimumWidth: 100
                    Layout.minimumHeight: 32
                    verticalAlignment: Label.AlignVCenter
                    text: qsTrId('id_version')
                }
                Label {
                    Layout.minimumHeight: 32
                    Layout.fillWidth: true
                    text: device.version
                    verticalAlignment: Label.AlignVCenter
                }
                Label {
                    Layout.minimumHeight: 32
                    text: qsTrId('id_bluetooth')
                    verticalAlignment: Label.AlignVCenter
                }
                Label {
                    Layout.minimumHeight: 32
                    text: device.versionInfo.JADE_CONFIG === 'NORADIO' ? qsTrId('id_not_available_noradio_build') : qsTrId('id_available')
                    verticalAlignment: Label.AlignVCenter
                }
                Label {
                    Layout.minimumHeight: 32
                    text: qsTrId('id_update')
                    verticalAlignment: Label.AlignVCenter
                }
                RowLayout {
                    GButton {
                        padding: 4
                        topInset: 0
                        bottomInset: 0
                        highlighted: (self.device && self.device.updateRequired) || !!update_dialog.controller.firmwareAvailable
                        enabled: !firmware_controller.fetching
                        text: {
                            if (self.device.updateRequired) return qsTrId('id_new_jade_firmware_required')
                            const fw = update_dialog.controller.firmwareAvailable
                            if (fw) return `${fw.version} available`
                            return qsTrId('id_check_for_updates')
                        }
                        onClicked: {
                            if (Object.keys(firmware_controller.index).length === 0) {
                                firmware_controller.enabled = true
                            } else {
                                update_dialog.advancedUpdate()
                            }
                        }
                    }
                    BusyIndicator {
                        Layout.preferredHeight: 32
                        running: firmware_controller.fetching
                        visible: running
                    }
                    HSpacer {}
                }
            }
        }
        Loader {
            Layout.margins: constants.s2
            Layout.alignment: Qt.AlignCenter
            active: self.device.versionInfo.JADE_NETWORKS === 'TEST' && !Settings.enableTestnet
            visible: active
            sourceComponent: Label {
                horizontalAlignment: Text.AlignHCenter
                padding: 8
                background: Rectangle {
                    radius: 4
                    color: 'white'
                }
                font.capitalization: Font.AllUppercase
                font.styleName: 'Medium'
                color: 'black'
                font.pixelSize: 10
                text: qsTrId('id_jade_was_initialized_for_testnet') + '\n' + qsTrId('id_enable_testnet_in_app_settings')
            }
        }
        Page {
            Layout.fillWidth: true
            background: null
            visible: !self.device.updateRequired && !(self.device.versionInfo.JADE_NETWORKS === 'TEST' && !Settings.enableTestnet)
            header: Label {
                text: qsTrId('id_wallets')
                font.pixelSize: 20
                font.styleName: 'Bold'
                bottomPadding: constants.s1
            }
            contentItem: ColumnLayout {
                spacing: 0
                Pane {
                    Layout.fillWidth: true
                    padding: 0
                    bottomPadding: 8
                    background: Item {
                        Rectangle {
                            width: parent.width
                            height: 1
                            y: parent.height - 1
                            color: constants.c600
                        }
                    }
                    contentItem: RowLayout {
                        spacing: constants.s1
                        Label {
                            text: qsTrId('id_network')
                            color: constants.c300
                            Layout.minimumWidth: 150
                        }
                        Label {
                            text: qsTrId('Type')
                            color: constants.c300
                            Layout.minimumWidth: 150
                        }
                        Label {
                            Layout.fillWidth: true
                            text: qsTrId('id_wallet')
                            color: constants.c300
                        }
                        Label {
                            Layout.minimumWidth: 150
                            text: qsTrId('id_actions')
                            color: constants.c300
                        }
                    }
                }
                Repeater {
                    model: {
                        if (self.device.updateRequired) return []
                        const nets = self.device.versionInfo.JADE_NETWORKS
                        const networks = []
                        if (nets === 'ALL' || nets === 'MAIN') {
                            networks.push({ id: 'mainnet' })
                            networks.push({ id: 'electrum-mainnet' })
                            networks.push({ id: 'liquid' })
                            networks.push({ id: 'electrum-liquid', comingSoon: true })
                        }
                        if (Settings.enableTestnet && (nets === 'ALL' || nets === 'TEST')) {
                            networks.push({ id: 'testnet' })
                            networks.push({ id: 'electrum-testnet' })
                            networks.push({ id: 'testnet-liquid' })
                            networks.push({ id: 'electrum-testnet-liquid', comingSoon: true })
                        }
                        return networks
                    }
                    delegate: NetworkSection {
                        comingSoon: !!modelData.comingSoon
                        network: NetworkManager.network(modelData.id)
                        device: self.device
                    }
                }
            }
        }
        VSpacer {
        }
    }
}
