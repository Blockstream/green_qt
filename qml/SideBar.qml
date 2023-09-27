import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

Pane {
    focusPolicy: Qt.ClickFocus
    topPadding: 0
    bottomPadding: 0
    leftPadding: 0
    rightPadding: 0
    background: Rectangle {
        color: '#13161D'
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

    contentItem: ColumnLayout {
        spacing: 10
        Item {
            Layout.minimumHeight: 20
        }
        SideButton {
            id: home_button
            enabled: true
            icon.source: 'qrc:/svg/home.svg'
            isCurrent: false
            // onClicked: navigation.push({ view: 'home' })
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
        SideButton {
            enabled: WalletManager.wallets.length > 0
            icon.source: 'qrc:/svg2/wallet.svg'
            isCurrent: (navigation.param?.view === 'wallets') || (navigation.param?.wallet ?? false)
            onClicked: navigation.push({ view: 'wallets' })
            text: qsTrId('id_wallets')
        }
        SideButton {
            icon.source: 'qrc:/svg/plus.svg'
            isCurrent: navigation.param.view === 'onboard'
            onClicked: navigation.set({ view: 'onboard' })
            text: qsTrId('id_add_wallet')
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
                SideButton {
                    icon.source: 'qrc:/svg/jade_emblem_on_transparent_rgb.svg'
                    isCurrent: navigation.param.view === 'jade'
                    onClicked: navigation.push({ view: 'jade' })
                    count: jade_view.count
                    text: 'Blockstream Jade'
                }
                SideButton {
                    icon.source: 'qrc:/svg/ledger-logo.svg'
                    isCurrent: navigation.param.view === 'ledger'
                    onClicked: navigation.push({ view: 'ledger' })
                    count: ledger_view.count
                    text: 'Ledger Nano'
                }
            }
        }
        VSpacer {
        }
        SideButton {
            icon.source: 'qrc:/svg2/gear.svg'
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
