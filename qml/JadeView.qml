import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

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
        active: navigation.param.view === 'jade'
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
                text: qsTrId('id_need_help') + ' ' + UtilJS.link(url, qsTrId('id_visit_the_blockstream_help'))
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
                        if (devices_list_view.itemAtIndex(i).device.versionInfo.EFUSEMAC.slice(-6) === navigation.param.device) {
                            return i
                        }
                    }
                    return 0
                }
                delegate: Button {
                    id: self
                    required property JadeDevice device
                    width: ListView.view.contentWidth
                    onClicked: navigation.set({ device: device.versionInfo.EFUSEMAC.slice(-6) })
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
                    JadeViewDevice {
                    }
                }
            }
        }
    }
}
