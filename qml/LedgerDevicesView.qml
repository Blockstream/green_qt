import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

MainPage {
    id: self
    property alias count: devices_list_view.count

    DeviceDiscoveryAgent {
    }
    DeviceListModel {
        id: device_list_model
        vendor: Device.Ledger
    }
    AnalyticsView {
        active: navigation.view === 'ledger'
        name: 'DeviceList'
    }
    header: MainPageHeader {
        contentItem: RowLayout {
            spacing: 12
            Label {
                text: qsTrId('id_ledger_devices')
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
                text: qsTrId('id_blockstream_store')
                highlighted: true
                onClicked: Qt.openUrlExternally('https://store.blockstream.com/product-category/physical_storage/')
                font.capitalization: Font.MixedCase
                leftPadding: 18
                rightPadding: 18
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
                source: 'qrc:/svg/ledger_nano_x.svg'
                sourceSize.height: 32
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                text: qsTrId('id_connect_your_ledger_to_use_it')
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
                        if (devices_list_view.itemAtIndex(i).device.uuid === navigation.param?.device) {
                            return i
                        }
                    }
                    return 0
                }
                delegate: Button {
                    id: self
                    required property LedgerDevice device
                    width: ListView.view.contentWidth
                    onClicked: navigation.set({ device: device.uuid })
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
                            text: switch (self.device?.type) {
                                case Device.LedgerNanoS: return 'Nano S'
                                case Device.LedgerNanoX: return 'Nano X'
                                default: return ''
                            }
                            font.pixelSize: 16
                        }
                        Label {
                            text: {
                                switch (self.device?.state ?? LedgerDevice.StateUnknown) {
                                    case LedgerDevice.StateApp:
                                        return self.device.appName + ' ' + self.device.appVersion
                                    case LedgerDevice.StateDashboard:
                                        return qsTrId('id_firmware') + ' ' + self.device.appVersion
                                    case LedgerDevice.StateLocked:
                                        return qstrId('id_locked')
                                    case LedgerDevice.StateUnknown:
                                    default:
                                        return qsTrId('id_loading')
                                }
                            }
                        }
                        RowLayout {
                            spacing: 16
                            Image {
                                Layout.preferredHeight: 24
                                Layout.preferredWidth: 24
                                source: 'qrc:/svg/usbAlt.svg'
                            }
                            HSpacer {
                            }
                            Image {
                                Layout.alignment: Qt.AlignLeft
                                smooth: true
                                mipmap: true
                                fillMode: Image.PreserveAspectFit
                                horizontalAlignment: Image.AlignHCenter
                                verticalAlignment: Image.AlignVCenter
                                source: switch (self.device?.type) {
                                    case Device.LedgerNanoS: return 'qrc:/svg/ledger_nano_s.svg'
                                    case Device.LedgerNanoX: return 'qrc:/svg/ledger_nano_x.svg'
                                    default: return ''
                                }
                                sourceSize.height: 24
                            }
                        }
                    }
                }
            }
            StackLayout {
                SplitView.fillWidth: true
                SplitView.minimumWidth: 600// children[currentIndex+1].implicitWidth
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
        property Network network
        property LedgerDevice device
        Layout.fillWidth: true
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
        LedgerDeviceController {
            id: controller
            device: self.device
            network: self.network
            onLoginDone: {
                Analytics.recordEvent('wallet_login', AnalyticsJS.segmentationWalletLogin(controller.wallet, { method: 'hardware' }))
                navigation.push({ view: self.network.key, wallet: controller.wallet.id })
            }
        }
        contentItem: RowLayout {
            spacing: constants.s1
            RowLayout {
                Layout.fillWidth: false
                Layout.minimumWidth: 150
                spacing: constants.s1
                Image {
                    source: UtilJS.iconFor(self.network)
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
                text: controller.wallet?.name ?? ''
            }
            ProgressBar {
                Layout.maximumWidth: 32
                Layout.minimumWidth: 32
                visible: controller.dispatcher.busy
                indeterminate: visible
            }
            RowLayout {
                Layout.fillWidth: false
                Layout.minimumWidth: 180
                GButton {
                    visible: (!controller.wallet || !controller.wallet.context) && controller.enabled
                    enabled: !controller.wallet?.context && !controller.dispatcher.busy
                    text: qsTrId('id_login')
                    onClicked: controller.login()
                }
                GButton {
                    visible: controller.wallet?.context ?? false
                    text: qsTrId('id_go_to_wallet')
                    onClicked: navigation.set({ view: self.network.key, wallet: controller.wallet.id })
                }
                Label {
                    visible: !controller.enabled
                    text: qsTrId('Select %1 app').arg(controller.appName)
                }
            }
//            TaskDispatcherInspector {
//                dispatcher: controller.dispatcher
//                Layout.minimumHeight: 100
//                Layout.minimumWidth: 100
//            }
        }
    }

    component View: ColumnLayout {
        id: self
        required property LedgerDevice device
        spacing: constants.s2
        Layout.minimumWidth: implicitWidth

        Page {
            Layout.fillWidth: true
            background: null
            header: Label {
                text: qsTrId('id_wallets')
                font.pixelSize: 20
                font.styleName: 'Bold'
                bottomPadding: constants.s1
            }
            contentItem: ColumnLayout {
                spacing: 0
                Label {
                    Layout.fillWidth: true
                    Layout.margins: 16
                    padding: 8
                    visible: self.device.state === LedgerDevice.StateDashboard && self.device.compatible
                    text: qsTrId('id_ledger_dashboard_detected')
                    horizontalAlignment: Label.AlignHCenter
                    background: Rectangle {
                        border.width: 0.5
                        border.color: 'white'
                        radius: 8
                        opacity: 0.5
                        color: 'transparent'
                    }
                }
                Loader {
                    id: ledger_unsupported_warning
                    Layout.fillWidth: true
                    Layout.margins: 16
                    active: !self.device.compatible
                    visible: active
                    sourceComponent: GPane {
                        padding: 8
                        background: Rectangle {
                            border.width: 0.5
                            border.color: 'white'
                            radius: 8
                            opacity: 0.5
                            color: 'transparent'
                        }
                        contentItem: ColumnLayout {
                            spacing: 12
                            Label {
                                Layout.alignment: Qt.AlignCenter
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                text: qsTrId('Install Bitcoin Legacy app on your Ledger')
                                horizontalAlignment: Label.AlignHCenter
                                wrapMode: Label.WrapAnywhere
                            }
                            Label {
                                Layout.alignment: Qt.AlignCenter
                                textFormat: Text.RichText
                                text: UtilJS.link('https://help.blockstream.com/hc/en-us/articles/16789393282201-How-do-I-use-my-Ledger-Nano-S-or-X-with-Green#h_01GW4FRJXCRRRGC4QAX0HC02S2', qsTrId('id_read_more'))
                                onLinkActivated: Qt.openUrlExternally(link)
                            }
                        }
                    }
                }
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
                        const networks = []
                        const supports_liquid = device.type === Device.LedgerNanoS
                        if (!ledger_unsupported_warning.active) {
                            networks.push({ id: 'mainnet' })
                            networks.push({ id: 'electrum-mainnet' })
                        }
                        if (supports_liquid) {
                            networks.push({ id: 'liquid' })
                        }
                        if (Settings.enableTestnet) {
                            networks.push({ id: 'testnet' })
                            networks.push({ id: 'electrum-testnet' })
                        }
                        if (Settings.enableTestnet && supports_liquid) {
                            networks.push({ id: 'testnet-liquid' })
                        }
                        return networks
                    }
                    delegate: NetworkSection {
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
