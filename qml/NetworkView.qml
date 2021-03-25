import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.13
import QtQuick.Window 2.12

Item {
    id: self
    required property string title
    required property string network
    readonly property WalletView currentWalletView: {
        for (let i = 0; i < wallet_view_repeater.count; ++i) {
            const view = wallet_view_repeater.itemAt(i)
            if (view.match) return view
        }
        return null
    }

    Repeater {
        id: wallet_view_repeater
        model: WalletListModel {
            justAuthenticated: true
            network: self.network
        }
        delegate: WalletView {
            property bool match: wallet.ready && window.location.startsWith(wallet_view.location)
            id: wallet_view
            anchors.fill: parent
            z: match ? 1 : -1
        }
    }

    IndexView {
        anchors.fill: parent
    }

    component IndexView: MainPage {
        header: MainPageHeader {
            contentItem: RowLayout {
                spacing: 16
                Image {
                    sourceSize.height: 32
                    sourceSize.width: 32
                    source: icons[network]
                }
                Label {
                    text: self.title
                    font.pixelSize: 24
                    font.styleName: 'Medium'
                    Layout.fillWidth: true
                }
                Button {
                    text: qsTrId('id_create_new_wallet')
                    highlighted: true
                    onClicked: pushLocation(`/${network}/signup`)
                }
                Button {
                    flat: true
                    text: qsTrId('id_restore_green_wallet')
                    onClicked: pushLocation(restore_dialog.location)
                }
            }
        }
        contentItem: ColumnLayout {
            MainPageSection {
                Layout.fillWidth: true
                visible: grid_view.count > 0
                title: qsTrId('id_logged_in_wallets')
                contentItem: Item {
                    clip: true
                    implicitHeight: 232
                GridView {
                    id: grid_view
                    anchors.fill: parent
                    anchors.margins: 16
                    cellWidth: height * 1.3
                    cellHeight: height
                    flow: GridView.FlowTopToBottom
                    model: WalletListModel {
                        justReady: true
                        network: self.network
                    }
                    delegate: Flipable {
                        id: flipable
                        width: grid_view.cellWidth
                        height: grid_view.cellHeight
                        property bool flipped: false
                        transform: Rotation {
                            id: rotation
                            origin.x: flipable.width/2
                            origin.y: flipable.height/2
                            axis.x: 0; axis.y: 1; axis.z: 0     // set axis.y to 1 to rotate around y-axis
                            angle: flipped ? 180 : 0    // the default angle
                            Behavior on angle {
                                SmoothedAnimation {
                                    velocity: 360
                                }
                            }
                        }
                        back: ItemDelegate {
                            anchors.fill: parent
                            anchors.margins: 8
                            background: Rectangle {
                                border.width: 1
                                border.color: Qt.rgba(1, 1, 1, 0.1)
                                color: Qt.rgba(1, 1, 1, grid_delegate.hovered ? 0.05 : 0.01)
                                radius: 4
                            }
                            contentItem: ColumnLayout {
                                Button {
                                    flat: true
                                    text: ('Logout')
                                    onClicked: wallet.disconnect()
                                }
                                Button {
                                    text: 'Cancel'
                                    onClicked: flipable.flipped = false
                                }
                            }
                        }
                        front: ItemDelegate {
                            id: grid_delegate
                            anchors.fill: parent
                            anchors.margins: 8
                            background: Rectangle {
                                border.width: 1
                                border.color: Qt.rgba(1, 1, 1, 0.1)
                                color: Qt.rgba(1, 1, 1, grid_delegate.hovered ? 0.05 : 0.01)
                                radius: 4
                            }
                            contentItem: ColumnLayout {
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    color: 'black'
                                    clip: true
                                    ShaderEffectSource {
                                        readonly property real scale: {
                                            if (!sourceItem) return 1
                                            if (sourceItem.width * parent.height < sourceItem.height * parent.width) {
                                                return sourceItem.width > 0 ? parent.width / sourceItem.width : 1
                                            } else {
                                                return sourceItem.height > 0 ? parent.height / sourceItem.height : 1
                                            }
                                        }
                                        mipmap: true
                                        width: sourceItem ? sourceItem.width * scale : 0
                                        height: sourceItem ? sourceItem.height * scale : 0
                                        sourceItem: {
                                            for (let i = 0; i < wallet_view_repeater.count; ++i) {
                                                const item = wallet_view_repeater.itemAt(i)
                                                if (item.wallet === wallet) return item.contentItem
                                            }
                                            return null
                                        }
                                    }
                                }
                                RowLayout {
                                    Label {
                                        Layout.fillWidth: true
                                        text: wallet.name
                                    }
                                    ToolButton {
                                        text: '\u22EF'
                                        onClicked: flipable.flipped = true
                                    }
                                }
                            }
                            onClicked: pushLocation(`/${network}/${wallet.id}`)
                        }
                    }
                    ScrollIndicator.horizontal: ScrollIndicator {}
                }
                }
            }
            MainPageSection {
                Layout.fillHeight: true
                Layout.fillWidth: true
                title: qsTrId('id_all_wallets')
                contentItem: Item {
                    clip: true
                    ListView {
                        id: wallet_list_view
                        anchors.fill: parent
                        anchors.margins: 16
                        currentIndex: -1
                        model: WalletListModel {
                            withoutDevice: true
                            network: self.network
                        }
                        delegate: WalletDelegate {}
                        ScrollIndicator.vertical: ScrollIndicator {}
                    }
                }
            }
        }
    }

    DialogLoader {
        readonly property string location: `/${network}/signup`
        id: signup_dialog
        active: matchesLocation(location)
        dialog: SignupDialog {
            network: NetworkManager.network(self.network)
            onRejected: popLocation()
        }
    }

    DialogLoader {
        readonly property string location: `/${network}/restore`
        id: restore_dialog
        active: matchesLocation(location)
        dialog: RestoreWallet {
            network: NetworkManager.network(self.network)
            onRejected: popLocation()
        }
    }

    component WalletDelegate: ItemDelegate {
        id: delegate
        required property Wallet wallet
        background: Rectangle {
            color: Qt.rgba(1, 1, 1, delegate.hovered ? 0.05 : 0)
            Rectangle {
                width: parent.width
                height: 1
                opacity: 0.1
                color: 'white'
                anchors.bottom: parent.bottom
            }
        }
        contentItem: RowLayout {
            Label {
                text: wallet.device ? wallet.device.name : wallet.name
            }
            Item {
                Layout.fillWidth: true
                height: 1
            }
            Label {
                visible: wallet.loginAttemptsRemaining === 0
                text: '\u26A0'
                font.pixelSize: 18
                ToolTip.text: qsTrId('id_no_attempts_remaining')
                ToolTip.visible: !valid && delegate.hovered
                ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
            }
            ToolButton {
                text: '\u22EF'
                onClicked: wallet_menu.open()
                Menu {
                    id: wallet_menu
                    MenuItem {
                        enabled: wallet.session && wallet.session.connected && wallet.authentication === Wallet.Authenticated && !wallet.device
                        text: qsTrId('id_log_out')
                        onTriggered: wallet.disconnect()
                    }
                    MenuItem {
                        text: qsTrId('id_remove_wallet')
                        onClicked: remove_wallet_dialog.createObject(window, { wallet }).open()
                    }
                }
            }
        }

        padding: 16
        width: wallet_list_view.width
        highlighted: ListView.isCurrentItem
        property bool valid: wallet.loginAttemptsRemaining > 0
        onClicked: pushLocation(`/${self.network}/${wallet.id}`)
    }
}
