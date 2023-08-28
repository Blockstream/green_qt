import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

Pane {
    focusPolicy: Qt.ClickFocus
    topPadding: 8
    bottomPadding: 8
    leftPadding: 8
    rightPadding: 8
    background: Rectangle {
        color: constants.c800
        Rectangle {
            width: 1
            anchors.right: parent.right
            height: parent.height
            color: Qt.rgba(0, 0, 0, 0.5)
        }
    }
    implicitWidth: 72
    Behavior on implicitWidth {
        NumberAnimation {
            duration: 300
            easing.type: Easing.InOutCubic
        }
    }

    component NetworkSideButton: SideButton {
        required property string network
        icon.source: UtilJS.iconFor(network)
        isCurrent: navigation.param.view === network && !navigation.param.wallet
        onClicked: navigation.push({ view: network })
    }

    contentItem: ColumnLayout {
        spacing: 8
        SideButton {
            id: home_button
            icon.source: 'qrc:/svg/home.svg'
            isCurrent: (navigation.param?.view ?? 'home') === 'home'
            onClicked: navigation.push({ view: 'home' })
            text: qsTrId('id_home')
        }
        SideButton {
            visible: Settings.showNews
            icon.source: 'qrc:/svg/blockstream-logo.svg'
            isCurrent: navigation.param?.view === 'blockstream'
            onClicked: navigation.push({ view: 'blockstream' })
            text: 'Blockstream News'
            busy: blockstream_view.busy
        }
        RowLayout {
            ToolButton {
                id: create_sidebar_button
                background: Rectangle {
                    visible: create_sidebar_button.hovered
                    color: constants.c600
                    radius: 4
                }
                Layout.fillWidth: true
                icon.source: 'qrc:/svg/plus.svg'
                onClicked: navigation.set({ flow: 'signup' })
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                LeftArrowToolTip {
                    parent: create_sidebar_button
                    text: qsTrId('id_create_wallet')
                    visible: create_sidebar_button.hovered
                }
            }
        }
        Flickable {
            id: flickable
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            flickableDirection: Flickable.VerticalFlick
            contentHeight: layout.height
            contentWidth: flickable.width
            ScrollIndicator.vertical: ScrollIndicator { }
            ColumnLayout {
                id: layout
                spacing: 8
                width: flickable.contentWidth
                NetworkSideButton {
                    network: 'bitcoin'
                    text: 'Bitcoin'
                }
                NetworkSideButton {
                    visible: Settings.enableTestnet
                    network: 'testnet'
                    text: 'Bitcoin Testnet'
                }
                NetworkSideButton {
                    network: 'localtest'
                    text: 'Localtest'
                    visible: env !== 'Production' && Settings.enableTestnet
                }
                NetworkSideButton {
                    network: 'liquid'
                    text: 'Liquid'
                }
                NetworkSideButton {
                    visible: Settings.enableTestnet
                    network: 'testnet-liquid'
                    text: 'Liquid Testnet'
                }
                NetworkSideButton {
                    network: 'localtest-liquid'
                    text: 'Liquid Localtest'
                    visible: env !== 'Production' && Settings.enableTestnet
                }
                SideButton {
                    icon.source: 'qrc:/svg/jade_emblem_on_transparent_rgb.svg'
                    isCurrent: navigation.param.view === 'jade'
                    onClicked: navigation.push({ view: 'jade' })
                    count: jade_view.count
                    text: 'Blockstream Jade'
                }
//                Repeater {
//                    model: DeviceListModel {
//                        type: Device.BlockstreamJade
//                    }
//                    delegate: DeviceSideButton {
//                    }
//                }
                SideButton {
                    icon.source: 'qrc:/svg/ledger-logo.svg'
                    isCurrent: navigation.param.view === 'ledger'
                    onClicked: navigation.push({ view: 'ledger' })
                    count: ledger_view.count
                    text: 'Ledger Nano'
                }
//                Repeater {
//                    model: DeviceListModel {
//                        vendor: Device.Ledger
//                    }
//                    delegate: DeviceSideButton {
//                    }
//                }
            }
        }
        Item {
            Layout.minimumHeight: 16
        }
        SideButton {
            icon.source: 'qrc:/svg/appsettings.svg'
            isCurrent: navigation.param.view === 'preferences'
            onClicked: navigation.push({ view: 'preferences' })
            text: qsTrId('id_app_settings')
            icon.width: 24
            icon.height: 24
        }
    }

    component DeviceSideButton: SideButton {
        id: button
        required property Device device
        text: button.device.name
        isCurrent: navigation.param.device === button.device.uuid
        leftPadding: 12
        rightPadding: 12
        contentItem: RowLayout {
            spacing: constants.s1
            Item {
                Layout.alignment: Qt.AlignCenter
                implicitWidth: 32
                implicitHeight: 96
                Layout.maximumWidth: img.paintedHeight
                DeviceImage {
                    id: img
                    width: 96
                    height: 32
                    anchors.centerIn: parent
                    rotation: 90
                    device: button.device
                }
            }
        }
        onClicked: {
            const device = button.device
            if (device.type === Device.BlockstreamJade) {
                navigation.push({ view: 'jade', device: device.uuid })
            } else if (device.vendor === Device.Ledger) {
                navigation.push({ view: 'ledger', device: device.uuid })
            }
        }
    }
}
