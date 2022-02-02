import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13

Pane {
    focusPolicy: Qt.ClickFocus
    topPadding: 8
    bottomPadding: 8
    leftPadding: 8
    rightPadding: 8
    background: Rectangle {
        color: constants.c700
    }
    contentItem: ColumnLayout {
        spacing: 8
        SideButton {
            id: home_button
            icon.source: 'qrc:/svg/home.svg'
            location: '/home'
            text: 'Home'
        }
        SideLabel {
            text: qsTrId('id_wallets')
        }
        Flickable {
            id: flickable
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: layout.implicitWidth
            clip: true
            flickableDirection: Flickable.VerticalFlick
            contentHeight: layout.height
            contentWidth: layout.width
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
                SideButton {
                    icon.source: icons.bitcoin
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
                    icon.source: icons.testnet
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
                    icon.source: icons.liquid
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
                    icon.source: icons['testnet-liquid']
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
                    icon.source: 'qrc:/svg/blockstream-logo.svg'
                    location: '/jade'
                    count: jade_view.count
                    text: 'Blockstream'
                }
                SideButton {
                    icon.source: 'qrc:/svg/ledger-logo.svg'
                    location: '/ledger'
                    count: ledger_view.count
                    text: 'Ledger'
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
            text: qsTrId('App Settings')
            icon.width: 24
            icon.height: 24
        }
    }

    component SideLabel: SectionLabel {
        topPadding: 16
        leftPadding: 4
        bottomPadding: 4
        font.pixelSize: 10
        font.styleName: 'Medium'
    }
}
