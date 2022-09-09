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
    readonly property string location: `/${network}`
    readonly property WalletView currentWalletView: {
        for (let i = 0; i < wallet_view_repeater.count; ++i) {
            const view = wallet_view_repeater.itemAt(i)
            if (view.match) return view
        }
        return null
    }
    property bool active: {
        if (window.navigation.path === location) return true
        if (!window.navigation.path.startsWith(`/${network}/`)) return false
        const [,, wallet_id] = window.navigation.path.split('/')
        const wallet = WalletManager.wallet(wallet_id)
        return wallet && wallet.ready
    }

    Repeater {
        id: wallet_view_repeater
        model: WalletListModel {
            justAuthenticated: true
            network: self.network
        }
        delegate: WalletView {
            property bool match: wallet.ready && navigation.location.startsWith(wallet_view.location)
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
                Label {
                    text: self.title
                    font.pixelSize: 24
                    font.styleName: 'Medium'
                    Layout.fillWidth: true
                }
                GButton {
                    text: qsTrId('id_create_new_wallet')
                    highlighted: true
                    large: true
                    onClicked: navigation.go(`/${self.network}/signup`, { network: self.network, type: (self.network === 'liquid' ? undefined : 'default') })
                }
                GButton {
                    large: true
                    text: qsTrId('id_restore_green_wallet')
                    onClicked: navigation.go(`/${self.network}/restore`, { network: self.network })
                }
                GButton {
                    text: qsTrId('id_watchonly_login')
                    large: true
                    onClicked: watch_only_login_dialog.createObject(window).open()
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
        Component {
            id: watch_only_login_dialog
            WatchOnlyLoginDialog {
                network: NetworkManager.networkWithServerType(self.network, 'green')
            }
        }

        contentItem: ColumnLayout {
            MainPageSection {
                Layout.fillHeight: true
                Layout.fillWidth: true
                title: qsTrId('id_all_wallets')
                background: Item {
                    Text {
                        visible: wallet_list_view.count===0
                        text: qsTrId('id_looks_like_you_havent_used_a');
                        color: 'white'
                        anchors.centerIn: parent
                    }
                }
                contentItem: Item {
                    clip: true
                    GListView {
                        id: wallet_list_view
                        anchors.fill: parent
                        anchors.topMargin: 16
                        currentIndex: -1
                        model: WalletListModel {
                            network: self.network
                        }
                        delegate: WalletDelegate {
                            width: ListView.view.contentWidth
                        }
                    }
                }
            }
        }
    }

    component WalletDelegate: ItemDelegate {
        id: delegate
        required property Wallet wallet
        padding: 0
        leftPadding: 8
        rightPadding: 8
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
            spacing: constants.s1
            Image {
                fillMode: Image.PreserveAspectFit
                sourceSize.height: 24
                sourceSize.width: 24
                source: delegate.wallet.network.electrum ? 'qrc:/svg/key.svg' : 'qrc:/svg/multi-sig.svg'
            }
            Label {
                Layout.maximumWidth: delegate.width / 3
                Layout.minimumWidth: delegate.width / 3
                text: wallet.name
                elide: Label.ElideRight
            }
            Loader {
                active: 'type' in wallet.deviceDetails
                visible: active
                sourceComponent: DeviceBadge {
                    device: wallet.device
                    details: wallet.deviceDetails
                }
            }
            HSpacer {
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
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
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
        highlighted: ListView.isCurrentItem
        property bool valid: wallet.loginAttemptsRemaining > 0
        onClicked: navigation.go(`/${wallet.network.key}/${wallet.id}`)
    }
}
