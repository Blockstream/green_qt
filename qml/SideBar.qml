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
        color: constants.c700
        Rectangle {
            width: 1
            anchors.right: parent.right
            height: parent.height
            color: Qt.rgba(0, 0, 0, 0.5)
        }
    }
    implicitWidth: Settings.collapseSideBar ? 72 : 300
    Behavior on implicitWidth {
        NumberAnimation {
            duration: 300
            easing.type: Easing.InOutCubic
        }
    }
    contentItem: ColumnLayout {
        spacing: 8
        SideButton {
            id: home_button
            icon.source: 'qrc:/svg/home.svg'
            location: '/home'
            text: qsTrId('id_home')
        }
        SideButton {
            visible: Settings.showNews
            icon.source: 'qrc:/svg/blockstream-logo.svg'
            location: '/blockstream'
            text: 'Blockstream News'
            busy: blockstream_view.busy
        }
        RowLayout {
            SideLabel {
                text: qsTrId('id_wallets')
            }
            ToolButton {
                id: create_sidebar_button
                background: Rectangle {
                    visible: create_sidebar_button.hovered
                    color: constants.c600
                    radius: 4
                }
                Layout.fillWidth: Settings.collapseSideBar
                icon.source: 'qrc:/svg/plus.svg'
                icon.color: 'white'
                onClicked: navigation.go('/signup')
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
            MouseArea {
                width: layout.width
                height: Math.max(flickable.height - layout.height + flickable.contentY - 16, 0)
                y: layout.height + 16
                onDoubleClicked: {
                    flickable.forceActiveFocus(Qt.MouseFocusReason)
                    Settings.collapseSideBar = !Settings.collapseSideBar
                }
            }
            ColumnLayout {
                id: layout
                spacing: 8
                width: flickable.contentWidth
                SideButton {
                    icon.source: UtilJS.iconFor('bitcoin')
                    location: '/bitcoin'
                    text: 'Bitcoin'
                }
                Repeater {
                    model: WalletListModel {
                        justReady: true
                        network: 'bitcoin'
                    }
                    WalletSideButton {
                    }
                }
                SideButton {
                    visible: Settings.enableTestnet
                    icon.source: UtilJS.iconFor('testnet')
                    location: '/testnet'
                    text: 'Bitcoin Testnet'
                }
                Repeater {
                    model: WalletListModel {
                        justReady: true
                        network: 'testnet'
                    }
                    WalletSideButton {
                        visible: !Settings.collapseSideBar && Settings.enableTestnet
                    }
                }
                SideButton {
                    icon.source: UtilJS.iconFor('liquid')
                    location: '/liquid'
                    text: 'Liquid'
                }
                Repeater {
                    model: WalletListModel {
                        justReady: true
                        network: 'liquid'
                    }
                    WalletSideButton {
                    }
                }
                SideButton {
                    visible: Settings.enableTestnet
                    icon.source: UtilJS.iconFor('testnet-liquid')
                    location: '/testnet-liquid'
                    text: 'Liquid Testnet'
                }
                Repeater {
                    model: WalletListModel {
                        justReady: true
                        network: 'testnet-liquid'
                    }
                    WalletSideButton {
                    }
                }
                SideLabel {
                    text: qsTrId('id_devices')
                }
                SideButton {
                    icon.source: 'qrc:/svg/jade_emblem_on_transparent_rgb.svg'
                    location: '/jade'
                    count: jade_view.count
                    text: 'Blockstream Jade'
                }
                SideButton {
                    icon.source: 'qrc:/svg/ledger-logo.svg'
                    location: '/ledger'
                    count: ledger_view.count
                    text: 'Ledger Nano'
                }
            }
        }
        Item {
            Layout.minimumHeight: 16
        }
        SideButton {
            icon.source: Settings.collapseSideBar ? 'qrc:/svg/arrow_right.svg' : 'qrc:/svg/arrow_left.svg'
            text: Settings.collapseSideBar ? qsTrId('id_expand_sidebar') : qsTrId('id_collapse_sidebar')
            isCurrent: false
            onClicked: Settings.collapseSideBar = !Settings.collapseSideBar
        }
        SideButton {
            icon.source: 'qrc:/svg/appsettings.svg'
            location: '/preferences'
            text: qsTrId('id_app_settings')
            icon.width: 24
            icon.height: 24
        }
    }

    component SideLabel: Pane {
        id: label
        property string text
        background: null
        topPadding: 4
        leftPadding: 4
        bottomPadding: 4
        visible: !Settings.collapseSideBar
        Layout.fillWidth: true
        contentItem: SectionLabel {
            font.pixelSize: 10
            font.styleName: 'Medium'
            text: label.text
        }
    }
}
